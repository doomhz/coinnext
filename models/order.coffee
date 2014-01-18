OrderSchema = new Schema
  user_id:
    type: String
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
  fee:
    type: Number
  unit_price:
    type: Number
  status:
    type: String
    enum: ["open", "partial", "closed"]
    default: "open"
    index: true
  created:
    type: Date
    default: Date.now
    index: true

OrderSchema.set("autoIndex", false)

###
OrderSchema.path("unit_price").validate ()->
    console.log @
    return false
  , "Invalid unit price"
###

OrderSchema.statics.findOpenByUserAndCurrencies = (userId, currencies, callback)->
  Order.find({user_id: userId, status: "open"}).where("buy_currency").in(currencies).where("sell_currency").in(currencies).exec callback

OrderSchema.statics.findByStatusActionAndCurrencies = (status, action, currency1, currency2, callback)->
  query =
    status: status
  if action is "buy"
    query.action = action
    query.buy_currency = currency2
    query.sell_currency = currency1
    Order.find query, callback
  else if action is "sell"
    query.action = action
    query.buy_currency = currency1
    query.sell_currency = currency2
    Order.find query, callback
  else if action is "*"
    currencies = [currency1, currency2]
    Order.find(query).where("buy_currency").in(currencies).where("sell_currency").in(currencies).exec callback
  else
    callback "Wrong action", []

Order = mongoose.model("Order", OrderSchema)
exports = module.exports = Order