_             = require "underscore"
autoIncrement = require "mongoose-auto-increment"

OrderSchema = new Schema
  user_id:
    type: String
    index: true
  engine_id:
    type: Number
    index: true
  type:
    type: String
    enum: ["market", "limit"]
    index: true
  action:
    type: String
    enum: ["buy", "sell"]
    index: true
  buy_currency:
    type: String
    index: true
  sell_currency:
    type: String
    index: true
  amount:
    type: Number
  sold_amount:
    type: Number
    default: 0
  result_amount:
    type: Number
    default: 0
  fee:
    type: Number
  unit_price:
    type: Number
    index: true
  status:
    type: String
    enum: ["open", "partiallyCompleted", "completed"]
    default: "open"
    index: true
  published:
    type: Boolean
    default: false
    index: true
  created:
    type: Date
    default: Date.now
    index: true

OrderSchema.set("autoIndex", false)

autoIncrement.initialize mongoose
OrderSchema.plugin autoIncrement.plugin,
  model: "Order"
  field: "engine_id"

###
OrderSchema.path("unit_price").validate ()->
    console.log @
    return false
  , "Invalid unit price"
###

OrderSchema.methods.publish = (callback = ()->)->
  GLOBAL.walletsClient.send "publish_order", [@id], (err, res, body)=>
    if err
      console.error err
      return callback err, res, body
    if body and body.published
      Order.findById @id, callback
    else
      console.error "Could not publish the order - #{JSON.stringify(body)}"
      callback "Could not publish the order to the network"

OrderSchema.statics.findByOptions = (options = {}, callback)->
  dbQuery = Order.find({})
  if options.status is "open"
    dbQuery.where("status").in(["partiallyCompleted", "open"])
  if options.status is "completed"
    dbQuery.where
      status: options.status
  dbQuery.where({action: options.action})    if ["buy", "sell"].indexOf(options.action) > -1
  dbQuery.where({user_id: options.user_id})  if options.user_id
  if options.action is "buy"
    dbQuery.where
      buy_currency: options.currency1
      sell_currency: options.currency2
  else if options.action is "sell"
    dbQuery.where
      buy_currency: options.currency2
      sell_currency: options.currency1
  else if not options.action
    currencies = []
    currencies.push options.currency1  if options.currency1
    currencies.push options.currency2  if options.currency2
    if currencies.length > 1
      dbQuery.where("buy_currency").in(currencies).where("sell_currency").in(currencies)
    else if currencies.length is 1
      dbQuery.or([{buy_currency: currencies[0]}, {sell_currency: currencies[0]}])
  else
    callback "Wrong action", []
  dbQuery.exec callback

OrderSchema.statics.findByEngineId = (engineId, callback)->
  Order.findOne {engine_id: engineId}, callback

OrderSchema.statics.isValidTradeAmount = (amount)->
  _.isNumber(amount) and not _.isNaN(amount) and amount > 0

OrderSchema.statics.getMarketPrice = (currency1, currency2, callback)->
  Order.findOne({sell_currency: currency1, buy_currency: currency2, action: "sell"})
  .where("status").in(["partiallyCompleted", "open"])
  .sort({unit_price: "asc"}).exec (err, sellOrder)->
    return callback err  if err
    Order.findOne({buy_currency: currency1, sell_currency: currency2, action: "buy"})
    .where("status").in(["partiallyCompleted", "open"])
    .sort({unit_price: "desc"}).exec (err, buyOrder)->
      return callback err  if err
      sellPrice = if sellOrder then sellOrder.unit_price else 0
      buyPrice = if buyOrder then buyOrder.unit_price else 0
      callback null,
        sell: sellPrice
        buy: buyPrice

Order = mongoose.model("Order", OrderSchema)
exports = module.exports = Order