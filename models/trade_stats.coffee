TradeStatsSchema = new Schema
  type:
    type: String
    index:
      unique: true
  open_price:
    type: Number
    default: 0
  close_price:
    type: Number
    default: 0
  high_price:
    type: Number
    default: 0
  low_price:
    type: Number
    default: 0
  volume:
    type: Number
    default: 0
  start_time:
    type: Date


TradeStatsSchema.set("autoIndex", false)

TradeStats = mongoose.model "TradeStats", TradeStatsSchema
exports = module.exports = TradeStats