class App.TradeView extends App.MasterView

  model: null

  currency1: null

  currency2: null

  events:
    "click .market-switcher": "onMarketSwitch"
    "click .header-balance .amount": "onAmountClick"
    "submit .order-form": "onOrderSubmit"
    "keyup #buy-amount-input": "onBuyAmountChange"
    "keyup #sell-amount-input": "onSellAmountChange"

  initialize: (options = {})->
    $.subscribe "new-balance", @onNewBalance
    @currency1 = options.currency1
    @currency2 = options.currency2

  render: ()->
    @model.fetch
      success: ()=>
        @renderTradeStats()
        @renderMaketTicker()
      error: ()=>

  renderTradeStats: ()->
    @tpl = "coin-stats-tpl"
    stats = @model.get "#{@currency1}_#{@currency2}"
    @$("#coin-stats").html @template
      coinStats: stats
      currency1: @currency1
      currency2: @currency2

  renderMaketTicker: ()->
    @tpl = "market-ticker-tpl"
    @$("#market-ticker").html @template
      marketStats: @model

  onMarketSwitch: (ev)->
    $target = $(ev.target)
    @$("#limit-#{$target.attr("name")}-box,#market-#{$target.attr("name")}-box").hide()
    @$("##{$target.val()}-#{$target.attr("name")}-box").show()

  onOrderSubmit: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    order = new App.OrderModel
      type: $form.find("[name='type']").val()
      action: $form.find("[name='action']").val()
      sell_currency: $form.find("[name='sell_currency']").val()
      buy_currency: $form.find("[name='buy_currency']").val()
      amount: $form.find("[name='amount']").val()
      unit_price: $form.find("[name='unit_price']").val()
    order.save null,
      success: ()->
        $.publish "new-order", order
        $form.find("[name='amount']").val ""
        $form.find("[name='unit_price']").val ""
      error: (m, xhr)->
        $.publish "error", xhr

  onAmountClick: (ev)->
    ev.preventDefault()
    $target = $(ev.target)
    @$("##{$target.data('type')}-amount-input").val($target.data('amount'))

  onBuyAmountChange: (ev)->
    $target = $(ev.target)
    spendAmount = parseFloat $target.val()
    $result = $("#buy-amount-result")
    if _.isNumber(spendAmount) and not _.isNaN(spendAmount)
      fee = parseFloat $result.data("fee")
      lastPrice = 0.02776 #@model.get("#{@currency1}_#{@currency2}").last_price
      total = _.str.roundToThree spendAmount / lastPrice - fee
      #console.log spendAmount, fee, lastPrice, total
      $result.text total
    else
      $result.text 0

  onSellAmountChange: (ev)->
    $target = $(ev.target)
    spendAmount = parseFloat $target.val()
    $result = $("#sell-amount-result")
    if _.isNumber(spendAmount) and not _.isNaN(spendAmount)
      fee = parseFloat $result.data("fee")
      lastPrice = 0.02776 #@model.get("#{@currency1}_#{@currency2}").last_price
      total = _.str.roundToThree spendAmount * lastPrice - fee
      #console.log spendAmount, fee, lastPrice, total
      $result.text total
    else
      $result.text 0
