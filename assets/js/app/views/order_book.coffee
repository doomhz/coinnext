class App.OrderBookView extends App.MasterView

  tpl: null

  collection: null

  events:
    "click .order-book-order": "onOrderClick"

  initialize: (options = {})->
    @tpl = options.tpl  if options.tpl
    @$totalsEl = options.$totalsEl  if options.$totalsEl
    $.subscribe "new-order", @onNewOrder
    $.subscribe "order-completed", @onOrderMatched
    $.subscribe "order-partially-completed", @onOrderMatched
    $.subscribe "order-canceled", @onOrderCanceled

  render: ()->
    @collection.fetch
      success: ()=>
        @$el.empty()
        for order in @collection.getStacked()
          @$el.append @template
            order: order
        @renderVolume()  if @$totalsEl

  renderVolume: ()->
    @$totalsEl.text _.str.toFixed @collection.calculateVolume()

  onNewOrder: (ev, order)=>
    @render()

  onOrderMatched: (ev, order)=>
    unitPrice = _.str.toFixed order.get("unit_price")
    $existentOrder = @$("[data-unit-price='#{unitPrice}']")
    if $existentOrder.length
      $existentOrder.addClass "highlight"
      setTimeout ()=>
          $existentOrder.removeClass "highlight"  if $existentOrder.length
          @render()
        , 1000

  onOrderCanceled: (ev, data)=>
    @render()

  onOrderClick: (ev)->
    $row = $(ev.currentTarget)
    unitPrice = parseFloat $row.data "unit-price"
    action = $row.data "action"
    order = new App.OrderModel
      unit_price: unitPrice
      action: action
      amount: @collection.calculateVolumeForPriceLimit unitPrice
    $.publish "order-book-order-selected", order