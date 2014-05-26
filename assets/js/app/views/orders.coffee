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
    #$.subscribe "order-to-cancel", @onOrderToCancel
    $.subscribe "order-canceled", @onOrderCanceled
    #$.subscribe "order-to-add", @onOrderToAdd

  render: ()->
    @collection.fetch
      success: ()=>
        @collection.each (order)=>
          @$el.append @template
            order: order
        @renderVolume()  if @$totalsEl
        @toggleVisible()  if @hideOnEmpty

  renderVolume: ()->
    @$totalsEl.text @collection.calculateVolume()

  onNewOrder: (ev, order)=>
    @$el.empty()
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
      $existentOrder.find(".trade-price").text order.get("unit_price")
      $existentOrder.find(".trade-amount").text order.calculateFirstNoFeeAmount()
      $existentOrder.find(".trade-total").text order.calculateSecondNoFeeAmount()
      setTimeout ()->
          $existentOrder.removeClass "highlight"  if $existentOrder.length
        , 1000

  onOrderCanceled: (ev, data)=>
    @$el.empty()
    @render()

  onOrderToCancel: (ev, data)=>
    @$el.empty()
    @render()

  onOrderToAdd: (ev, data)=>
    @$el.empty()
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
          #@$el.find("tr[data-id='#{order.id}']").remove()
        error: (m, xhr)->
          $.publish "error", xhr
          $target.attr "disabled", false
          $target.text "Cancel"