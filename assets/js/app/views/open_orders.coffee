class App.OpenOrdersView extends App.MasterView

  tpl: "open-order-tpl"

  collection: null

  events:
    "click .cancel": "onCancelClick"

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

  onCancelClick: (ev)->
    ev.preventDefault()
    if confirm "Are you sure?"
      order = new App.OrderModel
        id: $(ev.target).data("id")
      order.destroy
        success: ()=>
          @$el.find("tr[data-id='#{order.id}']").remove()
        error: (m, xhr)->
          $.publish "error", xhr