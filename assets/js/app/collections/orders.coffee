class window.App.OrdersCollection extends Backbone.Collection

  type: null

  currency1: null

  currency2: null

  url: ()->
    url = "/orders"
    url += "/#{@type}"       if @type
    url += "/#{@action}"     if @action
    url += "/#{@currency1}"  if @currency1
    url += "/#{@currency2}"  if @currency2
    url

  model: window.App.OrderModel

  initialize: (models, options = {})->
    @type      = options.type
    @action    = options.action
    @currency1 = options.currency1
    @currency2 = options.currency2
