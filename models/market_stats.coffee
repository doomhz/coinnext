MARKETS = [
  "LTC_BTC", "PPC_BTC"
]

MarketStatsSchema = new Schema
  type:
    type: String
    index:
      unique: true
  label:
    type: String
  last_price:
    type: Number
    default: 0
  day_high:
    type: Number
    default: 0
  day_low:
    type: Number
    default: 0
  volume1:
    type: Number
    default: 0
  volume2:
    type: Number
    default: 0
  growth_ratio:
    type: Number
    default: 0
  today:
    type: Date

MarketStatsSchema.set("autoIndex", false)

MarketStatsSchema.methods.resetIfNotToday = ()->
  today = new Date().getDate()
  if today isnt @today.getDate()
    @today = new Date()
    @day_high = 0
    @day_low = 0
    @volume1 = 0
    @volume2 = 0

MarketStatsSchema.statics.getStats = (callback = ()->)->
  MarketStats.find {}, (err, marketStats)->
    stats = {}
    for stat in marketStats
      stats[stat.type] = stat
    callback err, stats

MarketStatsSchema.statics.trackFromOrder = (order, callback = ()->)->
  type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
  if order.action is "sell"
    MarketStats.findOne {type: type}, (err, marketStats)->
      marketStats.resetIfNotToday()
      marketStats.growth_ratio = MarketStats.calculateGrowthRatio marketStats.last_price, order.unit_price  if order.unit_price isnt marketStats.last_price
      marketStats.last_price = order.unit_price
      marketStats.day_high = order.unit_price  if order.unit_price > marketStats.day_high
      marketStats.day_low = order.unit_price  if order.unit_price < marketStats.day_low or marketStats.day_low is 0
      marketStats.volume1 += order.amount
      marketStats.volume2 += order.result_amount
      marketStats.save callback

MarketStatsSchema.statics.getMarkets = ()->
  MARKETS

MarketStatsSchema.statics.isValidMarket = (action, buyCurrency, sellCurrency)->
  market = "#{buyCurrency}_#{sellCurrency}"  if action is "buy"
  market = "#{sellCurrency}_#{buyCurrency}"  if action is "sell"
  MarketStats.getMarkets().indexOf(market) > -1

MarketStatsSchema.statics.calculateGrowthRatio = (lastPrice, newPrice)->
  parseFloat newPrice * 100 / lastPrice - 100

MarketStats = mongoose.model "MarketStats", MarketStatsSchema
exports = module.exports = MarketStats