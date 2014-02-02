class App.TradeView extends App.MasterView

  model: null

  tpl: "coin-stats-tpl"

  currency1: null

  currency2: null

  events:
    "click .market-switcher": "onMarketSwitch"
    "click .header-balance .amount": "onAmountClick"
    "submit .order-form": "onOrderSubmit"
    "keyup #buy-amount-input": "onBuyAmountChange"
    "keyup #sell-amount-input": "onSellAmountChange"

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

  onBuyAmountChange: (ev)->
    $target = $(ev.target)
    buyAmount = parseFloat $target.val()
    $result = @$("#buy-amount-result")
    if @isValidAmount buyAmount
      fee = parseFloat $result.data("fee")
      lastPrice = parseFloat @$("#market-buy-unit-price").val()
      total = _.str.roundToThree buyAmount * lastPrice - fee
      #console.log spendAmount, fee, lastPrice, total
      $result.text total
    else
      $result.text 0

  onSellAmountChange: (ev)->
    $target = $(ev.target)
    spendAmount = parseFloat $target.val()
    $result = @$("#sell-amount-result")
    if @isValidAmount spendAmount
      fee = parseFloat $result.data("fee")
      lastPrice = parseFloat @$("#market-sell-unit-price").val()
      total = _.str.roundToThree spendAmount * lastPrice - fee
      #console.log spendAmount, fee, lastPrice, total
      $result.text total
    else
      $result.text 0

  onMarketStatsUpdated: (ev, data)=>
    @render()
