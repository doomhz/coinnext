class window.App.OrdersCollection extends Backbone.Collection

  type: null

  currency1: null

  currency2: null

  url: ()->
    url = "/orders"
    params = {}
    params.status    = @type       if @type
    params.action    = @action     if @action
    params.currency1 = @currency1  if @currency1
    params.currency2 = @currency2  if @currency2
    params.user_id   = @userId     if @userId
    url += "?#{$.param(params)}"

  model: window.App.OrderModel

  initialize: (models, options = {})->
    @type      = options.type
    @action    = options.action
    @currency1 = options.currency1
    @currency2 = options.currency2
    @userId    = options.userId