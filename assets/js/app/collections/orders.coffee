class window.App.OrdersCollection extends Backbone.Collection

  type: null

  currency1: null

  currency2: null

  published: null

  url: ()->
    url = "/orders"
    params = {}
    params.status    = @type       if @type
    params.action    = @action     if @action
    params.currency1 = @currency1  if @currency1
    params.currency2 = @currency2  if @currency2
    params.published = @published  if @published?
    params.user_id   = @userId     if @userId
    params.sort_by   = @orderBy    if @orderBy
    url += "?#{$.param(params)}"

  model: window.App.OrderModel

  initialize: (models, options = {})->
    @type      = options.type
    @action    = options.action
    @currency1 = options.currency1
    @currency2 = options.currency2
    @published = options.published
    @userId    = options.userId
    @orderBy   = options.orderBy

  calculateVolume: ()->
    total = 0
    @each (order)->
      total = App.math.add(total, order.calculateFirstNoFeeAmount())
    _.str.satoshiRound total

  calculateVolumeForPriceLimit: (unitPrice)->
    unitPrice = _.str.satoshiRound(unitPrice)
    totalAmount = 0
    @each (order)->
      orderPrice = _.str.satoshiRound(order.get("unit_price"))
      totalAmount = App.math.add(totalAmount, order.calculateFirstNoFeeAmount())  if orderPrice <= unitPrice
      return if orderPrice > unitPrice
    _.str.satoshiRound totalAmount

  getStacked: ()->
    stackedOrders = {}
    @each (order)->
      unitPrice = _.str.toFixed order.get("unit_price")
      stackId = "id-#{unitPrice}"
      stackedOrders[stackId] = new App.OrderModel  if not stackedOrders[stackId]
      stackedOrders[stackId].mergeWithOrder order
    _.values stackedOrders

  getIds: ()->
    ids = []
    @each (order)->
      ids.push order.id
    ids
