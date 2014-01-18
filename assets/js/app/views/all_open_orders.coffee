class App.AllOpenOrdersView extends App.MasterView

  tpl: "site-open-order-tpl"

  collection: null

  initialize: (options = {})->
    $.subscribe "new-order", @onNewOrder

  render: ()->
    @collection.fetch
      success: ()=>
        @collection.each (order)=>
          @$el.append @template
            order: order

  onNewOrder: (ev, order)=>
    @$el.empty()
    @render()
