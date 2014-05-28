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

  render: ()->
    @collection.fetch
      success: ()=>
        @renderOrders()
        @toggleVisible()  if @hideOnEmpty

  renderOrders: ()->
    @collection.each (order)=>
      $existentOrder = @$("[data-id='#{order.id}']")
      tpl = @template
        order: order
      @$el.prepend tpl  if not $existentOrder.length
      $existentOrder.replaceWith tpl  if $existentOrder.length

  onOrderCompleted: (ev, order)=>
    @render()

  onOrderPartiallyCompleted: (ev, order)=>
    @render()