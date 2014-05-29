class App.OrderLogsView extends App.MasterView

  tpl: null

  collection: null

  hideOnEmpty: false

  initialize: (options = {})->
    @tpl = options.tpl  if options.tpl
    @hideOnEmpty = options.hideOnEmpty  if options.hideOnEmpty
    @toggleVisible()
    $.subscribe "order-completed", @onOrderCompleted
    $.subscribe "order-partially-completed", @onOrderPartiallyCompleted

  render: (method)->
    @collection.fetch
      success: ()=>
        @renderOrders method
        @toggleVisible()  if @hideOnEmpty

  renderOrders: (method = "append")->
    @collection.each (order)=>
      $existentOrder = @$("[data-id='#{order.id}']")
      tpl = @template
        order: order
      @$el[method] tpl  if not $existentOrder.length
      $existentOrder.replaceWith tpl  if $existentOrder.length

  onOrderCompleted: (ev, order)=>
    @render "prepend"

  onOrderPartiallyCompleted: (ev, order)=>
    @render "prepend"