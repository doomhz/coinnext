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
    params.sort_by   = @sortBy     if @sortBy
    url += "?#{$.param(params)}"

  model: window.App.OrderLogModel

  initialize: (models, options = {})->
    @action    = options.action
    @currency1 = options.currency1
    @currency2 = options.currency2
    @userId    = options.userId
    @sortBy    = options.sortBy

  calculateVolume: ()->
    total = 0
    @each (order)->
      total = App.math.add(total, order.calculateFirstNoFeeAmount())
    _.str.satoshiRound total

  calculateVolumeForPriceLimit: (unitPrice)->
    totalAmount = 0
    reachedTheUnitPrice = false
    @each (order)->
      return  if reachedTheUnitPrice and unitPrice isnt _.str.satoshiRound(order.get("unit_price"))
      reachedTheUnitPrice = true  if unitPrice is _.str.satoshiRound(order.get("unit_price"))
      totalAmount = App.math.add(totalAmount, order.calculateFirstNoFeeAmount())
    _.str.satoshiRound totalAmount
