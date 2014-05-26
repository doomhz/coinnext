class App.OrderLogsView extends App.MasterView

  tpl: null

  collection: null

  hideOnEmpty: false

  initialize: (options = {})->
    @tpl = options.tpl  if options.tpl
    @hideOnEmpty = options.hideOnEmpty  if options.hideOnEmpty
    @toggleVisible()

  render: ()->
    @collection.fetch
      success: ()=>
        @collection.each (order)=>
          @$el.append @template
            order: order
        @toggleVisible()  if @hideOnEmpty

