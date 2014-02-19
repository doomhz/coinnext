class App.TradeView extends App.MasterView

  model: null

  tpl: "coin-stats-tpl"

  currency1: null

  currency2: null

  events:
    "click .market-switcher": "onMarketSwitch"
    "click .header-balance .amount": "onAmountClick"
    "submit .order-form": "onOrderSubmit"
    "keyup #market-buy-form #spend-amount-input": "onMarketBuyAmountChange"
    "keyup #limit-buy-form #buy-amount-input": "onLimitBuyAmountChange"
    "keyup #limit-buy-form #buy-unit-price": "onLimitBuyAmountChange"
    "keyup #sell-amount-input": "onSellAmountChange"
    "keyup #sell-unit-price": "onSellAmountChange"

  initialize: (options = {})->
    @currency1 = options.currency1
    @currency2 = options.currency2
    $.subscribe "market-stats-updated", @onMarketStatsUpdated

  render: ()->
    @model.fetch
      success: ()=>
        @renderTradeStats()
      error: ()=>

  renderTradeStats: ()->
    stats = @model.get "#{@currency1}_#{@currency2}"
    @$("#coin-stats").html @template
      coinStats: stats
      currency1: @currency1
      currency2: @currency2

  isValidAmount: (amount)->
    _.isNumber(amount) and not _.isNaN(amount) and amount > 0

  onMarketSwitch: (ev)->
    $target = $(ev.target)
    @$("#limit-#{$target.attr("name")}-box,#market-#{$target.attr("name")}-box").hide()
    @$("##{$target.val()}-#{$target.attr("name")}-box").show()

  onOrderSubmit: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    amount = parseFloat $form.find("[name='amount']").val()
    return $.publish "error", "Please submit a valid amount bigger than 0."  if not @isValidAmount amount
    order = new App.OrderModel
      type: $form.find("[name='type']").val()
      action: $form.find("[name='action']").val()
      sell_currency: $form.find("[name='sell_currency']").val()
      buy_currency: $form.find("[name='buy_currency']").val()
      amount: amount
      unit_price: $form.find("[name='unit_price']").val()
    order.save null,
      success: ()->
        $form.find("[name='amount']").val ""
      error: (m, xhr)->
        $.publish "error", xhr

  onAmountClick: (ev)->
    ev.preventDefault()
    $target = $(ev.target)
    $input = @$("##{$target.data('type')}-amount-input")
    $input.val($target.data('amount'))
    $input.trigger "keyup"

  onMarketBuyAmountChange: (ev)->
    $target = $(ev.target)
    $form = $target.parents("form")
    spendAmount = parseFloat $form.find("#spend-amount-input").val()
    $result = $form.find("#buy-amount-result")
    $fee = $form.find("#buy-fee")
    $subTotal = $form.find("#buy-subtotal")
    fee = parseFloat $fee.data("fee")
    lastPrice = parseFloat $form.find("#buy-unit-price").val()
    if @isValidAmount(spendAmount) and @isValidAmount(fee) and @isValidAmount(lastPrice)
      subTotal = _.str.roundToThree spendAmount / lastPrice
      totalFee = _.str.roundToThree subTotal / 100 * fee
      total = subTotal - totalFee
      #console.log fee, totalFee, lastPrice, total
      $fee.text totalFee
      $subTotal.text subTotal
      $result.text total
    else
      $result.text 0
      $fee.text 0
      $subTotal.text 0

  onLimitBuyAmountChange: (ev)->
    $target = $(ev.target)
    $form = $target.parents("form")
    buyAmount = parseFloat $form.find("#buy-amount-input").val()
    $result = $form.find("#buy-amount-result")
    $fee = $form.find("#buy-fee")
    $subTotal = $form.find("#buy-subtotal")
    fee = parseFloat $fee.data("fee")
    lastPrice = parseFloat $form.find("#buy-unit-price").val()
    if @isValidAmount(buyAmount) and @isValidAmount(fee) and @isValidAmount(lastPrice)
      subTotal = _.str.roundToThree buyAmount * lastPrice
      totalFee = _.str.roundToThree buyAmount / 100 * fee
      total = buyAmount - totalFee
      #console.log fee, totalFee, lastPrice, total
      $fee.text totalFee
      $subTotal.text subTotal
      $result.text total
    else
      $result.text 0
      $fee.text 0
      $subTotal.text 0

  onSellAmountChange: (ev)->
    $target = $(ev.target)
    $form = $target.parents("form")
    sellAmount = parseFloat $form.find("#sell-amount-input").val()
    $result = $form.find("#sell-amount-result")
    $fee = $form.find("#sell-fee")
    $subTotal = $form.find("#sell-subtotal")
    fee = parseFloat $fee.data("fee")
    lastPrice = parseFloat $form.find("#sell-unit-price").val()
    if @isValidAmount(sellAmount) and @isValidAmount(fee) and @isValidAmount(lastPrice)
      subTotal = _.str.roundToThree sellAmount * lastPrice
      totalFee = _.str.roundToThree subTotal / 100 * fee
      total = subTotal - totalFee
      #console.log fee, totalFee, lastPrice, total
      $fee.text totalFee
      $subTotal.text subTotal
      $result.text total
    else
      $result.text 0
      $fee.text 0
      $subTotal.text 0

  onMarketStatsUpdated: (ev, data)=>
    @render()
