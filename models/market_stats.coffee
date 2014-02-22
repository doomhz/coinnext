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
  last_buy_price:
    type: Number
    default: 0
  last_sell_price:
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
  growth:
    type: Boolean
    default: false
  growth_ratio:
    type: Number
    default: 0

MarketStatsSchema.set("autoIndex", false)

MarketStatsSchema.statics.getStats = (callback = ()->)->
  MarketStats.find {}, (err, marketStats)->
    stats = {}
    for stat in marketStats
      stats[stat.type] = stat
    callback err, stats

MarketStatsSchema.statics.trackFromOrder = (order, callback = ()->)->
  type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
  MarketStats.findOne {type: type}, (err, marketStats)->
    if order.action is "buy"
      marketStats.growth = marketStats.last_price <= order.unit_price
      marketStats.growth_ratio = (order.unit_price - marketStats.last_price) * (marketStats.last_price / 100)
      marketStats.last_price = order.unit_price
      marketStats.last_sell_price = order.unit_price  if order.action is "sell"
      marketStats.last_buy_price = order.unit_price  if order.action is "buy"
      marketStats.day_high = order.unit_price  if order.unit_price > marketStats.day_high
      marketStats.day_low = order.unit_price  if order.unit_price < marketStats.day_low
      marketStats.volume1 += order.amount
      marketStats.volume2 += order.result_amount
      marketStats.save callback

MarketStatsSchema.statics.getMarkets = ()->
  MARKETS

MarketStatsSchema.statics.isValidMarket = (action, buyCurrency, sellCurrency)->
  market = "#{buyCurrency}_#{sellCurrency}"  if action is "buy"
  market = "#{sellCurrency}_#{buyCurrency}"  if action is "sell"
  MarketStats.getMarkets().indexOf(market) > -1

MarketStats = mongoose.model "MarketStats", MarketStatsSchema
exports = module.exports = MarketStats