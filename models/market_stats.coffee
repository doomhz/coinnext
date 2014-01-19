MarketStatsSchema = new Schema
  BTC_LTC:
    label:
      type: String
      default: "LTC"
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
    growth:
      type: Boolean
      default: false
    growth_ratio:
      type: Number
      default: 0
  BTC_PPC:
    label:
      type: String
      default: "PPC"
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
    growth:
      type: Boolean
      default: false
    growth_ratio:
      type: Number
      default: 0

MarketStatsSchema.set("autoIndex", false)

MarketStatsSchema.statics.getStats = (callback = ()->)->
  MarketStats.findOne {}, (err, marketStats)->
    if not marketStats
      MarketStats.create {}, (err, marketStats)->
        callback err,
          BTC_LTC: marketStats.BTC_LTC
          BTC_PPC: marketStats.BTC_PPC
    else
      callback err,
          BTC_LTC: marketStats.BTC_LTC
          BTC_PPC: marketStats.BTC_PPC

MarketStats = mongoose.model "MarketStats", MarketStatsSchema
exports = module.exports = MarketStats