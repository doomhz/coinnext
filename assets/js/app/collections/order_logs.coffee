class window.App.OrderLogsCollection extends Backbone.Collection

  currency1: null

  currency2: null

  url: ()->
    url = "/order_logs"
    params = {}
    params.action    = @action     if @action
    params.currency1 = @currency1  if @currency1
    params.currency2 = @currency2  if @currency2
    params.user_id   = @userId     if @userId
    params.sort_by   = @orderBy    if @orderBy
    url += "?#{$.param(params)}"

  model: window.App.OrderLogModel

  initialize: (models, options = {})->
    @action    = options.action
    @currency1 = options.currency1
    @currency2 = options.currency2
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
