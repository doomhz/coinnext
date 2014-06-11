class App.OrdersView extends App.MasterView

  tpl: null

  collection: null

  hideOnEmpty: false

  events:
    "click .cancel": "onCancelClick"

  initialize: (options = {})->
    @tpl = options.tpl  if options.tpl
    @$totalsEl = options.$totalsEl  if options.$totalsEl
    @hideOnEmpty = options.hideOnEmpty  if options.hideOnEmpty
    @toggleVisible()
    $.subscribe "new-order", @onNewOrder
    $.subscribe "order-completed", @onOrderCompleted
    $.subscribe "order-partially-completed", @onOrderPartiallyCompleted
    $.subscribe "order-to-cancel", @onOrderToCancel
    $.subscribe "order-canceled", @onOrderCanceled
    $.subscribe "order-to-add", @onOrderToAdd

  render: ()->
    @collection.fetch
      success: ()=>
        @clearDeletedOrders()
        @renderOrders()
        @renderVolume()  if @$totalsEl
        @toggleVisible()  if @hideOnEmpty

  renderOrders: ()->
    @collection.each (order)=>
      $existentOrder = @$("[data-id='#{order.id}']")
      tpl = @template
        order: order
      @$el.append tpl  if not $existentOrder.length
      $existentOrder.replaceWith tpl  if $existentOrder.length

  clearDeletedOrders: ()->
    existentOrderIds = @collection.getIds()
    for row in @$(".order-row")
      $(row).remove()  if existentOrderIds.indexOf($(row).data("id")) is -1

  renderVolume: ()->
    @$totalsEl.text @collection.calculateVolume()

  onNewOrder: (ev, order)=>
    @render()

  onOrderCompleted: (ev, order)=>
    $existentOrder = @$("[data-id='#{order.id}']")
    if $existentOrder.length
      $existentOrder.addClass "highlight"
      setTimeout ()->
          $existentOrder.remove()  if $existentOrder.length
        , 1000

  onOrderPartiallyCompleted: (ev, order)=>
    $existentOrder = @$("[data-id='#{order.id}']")
    if $existentOrder.length
      $existentOrder.addClass "highlight"
      $existentOrder.find(".trade-price").text _.str.toFixed(order.get("unit_price"))
      $existentOrder.find(".trade-amount").text _.str.toFixed(order.calculateFirstNoFeeAmount())
      $existentOrder.find(".trade-total").text _.str.toFixed(order.calculateSecondNoFeeAmount())
      setTimeout ()->
          $existentOrder.removeClass "highlight"  if $existentOrder.length
        , 1000

  onOrderCanceled: (ev, data)=>
    @render()

  onOrderToCancel: (ev, data)=>
    @render()

  onOrderToAdd: (ev, data)=>
    @render()

  onCancelClick: (ev)->
    ev.preventDefault()
    if confirm "Are you sure?"
      $target = $(ev.target)
      $target.attr "disabled", true
      $target.text "Pending..."
      order = new App.OrderModel
        id: $(ev.target).data("id")
      order.destroy
        success: ()=>
        error: (m, xhr)->
          $.publish "error", xhr
          $target.attr "disabled", false
          $target.text "Cancel"
