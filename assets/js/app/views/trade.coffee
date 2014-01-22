class App.TradeView extends App.MasterView

  events:
    "click .market-switcher": "onMarketSwitch"
    "click .header-balance .amount": "onAmountClick"
    "submit .order-form": "onOrderSubmit"

  initialize: ()->
    $.subscribe "new-balance", @onNewBalance

  render: ()->
  
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
