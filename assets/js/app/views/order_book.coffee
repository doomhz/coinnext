class App.OrderBookView extends App.MasterView

  tpl: null

  collection: null

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
    @$totalsEl.text @collection.calculateVolume()

  onNewOrder: (ev, order)=>
    @render()

  onOrderMatched: (ev, order)=>
    unitPrice = _.str.satoshiRound order.get("unit_price")
    $existentOrder = @$("[data-unit-price='#{unitPrice}']")
    if $existentOrder.length
      $existentOrder.addClass "highlight"
      setTimeout ()=>
          $existentOrder.removeClass "highlight"  if $existentOrder.length
          @render()
        , 1000

  onOrderCanceled: (ev, data)=>
    @render()
