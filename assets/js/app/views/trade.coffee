class App.TradeView extends App.MasterView

  model: null

  tpl: "coin-stats-tpl"

  currency1: null

  currency2: null

  events:
    "click .market-switcher": "onMarketSwitch"
    "click .header-balance .amount": "onAmountClick"
    #"submit .order-form": "onOrderSubmit"
    "keyup #market-buy-form #spend-amount-input": "onMarketBuyAmountChange"
    "keyup #limit-buy-form #buy-amount-input": "onLimitBuyAmountChange"
    "keyup #limit-buy-form #buy-unit-price": "onLimitBuyAmountChange"
    "keyup #sell-amount-input": "onSellAmountChange"
    "keyup #sell-unit-price": "onSellAmountChange"

  initialize: (options = {})->
    @currency1 = options.currency1
    @currency2 = options.currency2
    $.subscribe "market-stats-updated", @onMarketStatsUpdated
    $.subscribe "payment-processed", @onPaymentProcessed
    $.subscribe "wallet-balance-loaded", @onWalletBalanceLoaded

  render: ()->
    @model.fetch
      success: ()=>
        @renderTradeStats()
      error: ()=>
    @setupFormValidators()

  renderTradeStats: ()->
    stats = @model.get "#{@currency1}_#{@currency2}"
    @$("#coin-stats").html @template
      coinStats: stats
      currency1: @currency1
      currency2: @currency2

  renderWalletBalance: (walletId)->
    wallet = new App.WalletModel
      id: walletId
    wallet.fetch
      success: ()=>
        @$("[data-wallet-balance-id='#{walletId}']").html _.str.satoshiRound(wallet.get("balance") + wallet.get("hold_balance"))
        @$("[data-wallet-hold-balance-id='#{walletId}']").text _.str.satoshiRound(wallet.get("hold_balance"))
        @$("[data-wallet-available-balance-id='#{walletId}']").text _.str.satoshiRound(wallet.get("balance"))

  setupFormValidators: ()->
    for orderForm in @$(".order-form")
      $(orderForm).validate
        rules:
          amount:
            required: true
            number: true
            min: 0.000001
          unit_price:
            required: true
            number: true
            min: 0.000001
        messages:
          amount:
            required: "Please provide an amount."
          unit_price:
            required: "Please provide an amount."
        submitHandler: (form)=>
          @onOrderSubmit form
          return false

  isValidAmount: (amount)->
    _.isNumber(amount) and not _.isNaN(amount) and amount > 0

  onMarketSwitch: (ev)->
    $target = $(ev.target)
    @$("#limit-#{$target.attr("name")}-box,#market-#{$target.attr("name")}-box").hide()
    @$("##{$target.val()}-#{$target.attr("name")}-box").show()

  onOrderSubmit: (form)->
    $form = $(form)
    amount = _.str.roundTo $form.find("[name='amount']").val(), 8
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
    amount = $target.data('amount')
    type = $target.data('type')
    $input = @$("##{type}-amount-input")
    unitPrice = parseFloat @$("##{type}-unit-price").val()
    resultAmount = if type is "buy" then _.str.roundTo(App.math.divide(amount, unitPrice), 8) else amount
    $input.val(resultAmount)
    $input.trigger "keyup"

  onMarketBuyAmountChange: (ev)->
    $target = $(ev.target)
    $form = $target.parents("form")
    spendAmount = _.str.roundTo $form.find("#spend-amount-input").val(), 8
    $result = $form.find("#buy-amount-result")
    $fee = $form.find("#buy-fee")
    $subTotal = $form.find("#buy-subtotal")
    fee = _.str.roundTo $fee.data("fee"), 8
    lastPrice = _.str.roundTo $form.find("#buy-unit-price").val(), 8
    if @isValidAmount(spendAmount) and @isValidAmount(fee) and @isValidAmount(lastPrice)
      subTotal = _.str.roundTo App.math.divide(spendAmount, lastPrice), 8
      totalFee = _.str.roundTo App.math.select(subTotal).divide(100).multiply(fee).done(), 8
      total = _.str.roundTo App.math.add(subTotal, -totalFee), 8
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
    buyAmount = _.str.roundTo $form.find("#buy-amount-input").val(), 8
    $result = $form.find("#buy-amount-result")
    $fee = $form.find("#buy-fee")
    $subTotal = $form.find("#buy-subtotal")
    fee = _.str.roundTo $fee.data("fee"), 8
    lastPrice = _.str.roundTo $form.find("#buy-unit-price").val(), 8
    if @isValidAmount(buyAmount) and @isValidAmount(fee) and @isValidAmount(lastPrice)
      subTotal = _.str.roundTo App.math.multiply(buyAmount, lastPrice), 8
      totalFee = _.str.roundTo App.math.select(buyAmount).divide(100).multiply(fee).done(), 8
      total = _.str.roundTo App.math.add(buyAmount, -totalFee), 8
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
    sellAmount = _.str.roundTo $form.find("#sell-amount-input").val(), 8
    $result = $form.find("#sell-amount-result")
    $fee = $form.find("#sell-fee")
    $subTotal = $form.find("#sell-subtotal")
    fee = _.str.roundTo $fee.data("fee"), 8
    lastPrice = _.str.roundTo $form.find("#sell-unit-price").val(), 8
    if @isValidAmount(sellAmount) and @isValidAmount(fee) and @isValidAmount(lastPrice)
      subTotal = _.str.roundTo App.math.multiply(sellAmount, lastPrice), 8
      totalFee = _.str.roundTo App.math.select(subTotal).divide(100).multiply(fee).done(), 8
      total = _.str.roundTo App.math.add(subTotal, -totalFee), 8
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

  onPaymentProcessed: (ev, payment)=>
    @renderWalletBalance payment.get("wallet_id")

  onWalletBalanceLoaded: (ev, wallet)=>
    @renderWalletBalance wallet.id
