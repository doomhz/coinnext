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
    $.subscribe "wallet-balance-changed", @onWalletBalanceChanged
    $.subscribe "order-book-order-selected", @onOrderBookOrderSelected

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
        @$("[data-wallet-balance-id='#{walletId}']").html _.str.toFixed _.str.satoshiRound(wallet.get("balance") + wallet.get("hold_balance"))
        @$("[data-wallet-hold-balance-id='#{walletId}']").text _.str.toFixed _.str.satoshiRound(wallet.get("hold_balance"))
        @$("[data-wallet-available-balance-id='#{walletId}']").text _.str.toFixed _.str.satoshiRound(wallet.get("balance"))

  setupFormValidators: ()->
    for orderForm in @$(".order-form")
      $(orderForm).validate
        rules:
          amount:
            required: true
            number: true
            min: 0.0000001
          unit_price:
            required: true
            number: true
            min: 0.00000001
        messages:
          amount:
            required: "Please provide an amount."
            min: "Please provide an amount bigger than 0.0000001"
          unit_price:
            required: "Please provide an amount."
            min: "Please provide an amount bigger than 0.000001"
        submitHandler: (form)=>
          @onOrderSubmit form
          return false

  isValidAmount: (amount)->
    _.isNumber(amount) and not _.isNaN(amount) and _.isFinite(amount) and amount > 0

  onMarketSwitch: (ev)->
    $target = $(ev.target)
    @$("#limit-#{$target.attr("name")}-box,#market-#{$target.attr("name")}-box").hide()
    @$("##{$target.val()}-#{$target.attr("name")}-box").show()

  onOrderSubmit: (form)->
    $form = $(form)
    $form.find("#error-cnt").empty()
    amount = _.str.satoshiRound $form.find("[name='amount']").val()
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
        $.publish "error", [xhr, $form]

  onAmountClick: (ev)->
    ev.preventDefault()
    $target = $(ev.currentTarget)
    amount = parseFloat $target.find("[data-wallet-available-balance-id]").text()
    type = $target.data('type')
    $input = @$("##{type}-amount-input")
    unitPrice = _.str.satoshiRound @$("##{type}-unit-price").val()
    resultAmount = if type is "buy" then _.str.satoshiRound App.math.divide(amount, unitPrice) else amount
    resultAmount = if @isValidAmount(resultAmount) then resultAmount else 0
    $input.val(_.str.toFixed(resultAmount))
    $input.trigger "keyup"

  onLimitBuyAmountChange: (ev)->
    $target = $(ev.target)
    $form = $target.parents("form")
    buyAmount = _.str.satoshiRound $form.find("#buy-amount-input").val()
    $result = $form.find("#buy-amount-result")
    $fee = $form.find("#buy-fee")
    $subTotal = $form.find("#buy-subtotal")
    fee = _.str.satoshiRound $fee.data("fee")
    lastPrice = _.str.satoshiRound $form.find("#buy-unit-price").val()
    if @isValidAmount(buyAmount) and @isValidAmount(lastPrice)
      subTotal = _.str.satoshiRound App.math.multiply(buyAmount, lastPrice)
      totalFee = _.str.satoshiRound App.math.select(buyAmount).divide(100).multiply(fee).done()
      total = _.str.satoshiRound App.math.add(buyAmount, -totalFee)
      $fee.text _.str.toFixed totalFee
      $subTotal.text _.str.toFixed subTotal
      $result.text _.str.toFixed total
    else
      $result.text 0
      $fee.text 0
      $subTotal.text 0

  onSellAmountChange: (ev)->
    $target = $(ev.target)
    $form = $target.parents("form")
    sellAmount = _.str.satoshiRound $form.find("#sell-amount-input").val()
    $result = $form.find("#sell-amount-result")
    $fee = $form.find("#sell-fee")
    $subTotal = $form.find("#sell-subtotal")
    fee = _.str.satoshiRound $fee.data("fee")
    lastPrice = _.str.satoshiRound $form.find("#sell-unit-price").val()
    if @isValidAmount(sellAmount) and @isValidAmount(lastPrice)
      subTotal = _.str.satoshiRound App.math.multiply(sellAmount, lastPrice)
      totalFee = _.str.satoshiRound App.math.select(subTotal).divide(100).multiply(fee).done()
      total = _.str.satoshiRound App.math.add(subTotal, -totalFee)
      $fee.text _.str.toFixed totalFee
      $subTotal.text _.str.toFixed subTotal
      $result.text _.str.toFixed total
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

  onWalletBalanceChanged: (ev, wallet)=>
    @renderWalletBalance wallet.id

  onOrderBookOrderSelected: (ev, order)=>
    @$("#buy-unit-price,#sell-unit-price").val(_.str.toFixed(order.get("unit_price")))
    @$("#buy-amount-input").val(_.str.toFixed(order.get("amount"))).trigger("keyup")  if order.get("action") is "sell"
    @$("#sell-amount-input").val(_.str.toFixed(order.get("amount"))).trigger("keyup")  if order.get("action") is "buy"
