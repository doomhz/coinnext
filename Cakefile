fs = require "fs"
environment = process.env.NODE_ENV or 'development'
config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', 'utf8'))[environment]
GLOBAL.appConfig = ()-> config
ClientSocket = require "./lib/client_socket"
userSocket = new ClientSocket
async = require "async"
_ = require "underscore"

task "db:ensure_indexes", "Create indexes for all the collections", ()->
  require('./models/db_connect_mongo')
  _s         = require "underscore.string"
  modelNames = [
    "User", "Chat", "MarketStats", "Order", "Payment",
    "Transaction", "Wallet"
  ]
  for modelName in modelNames
    model = require "./models/#{_s.underscored(modelName)}"
    model.ensureIndexes()

task "db:seed_market_stats", "Seed default market stats", ()->
  require('./models/db_connect_mongo')
  MarketStats = require "./models/market_stats"
  MarketStats.collection.drop (err) ->
    marketStats = [
      {type: "LTC_BTC", label: "LTC"}
      {type: "PPC_BTC", label: "PPC"}
    ]
    saveMarket = (market, cb)->
      MarketStats.create market, cb
    async.mapSeries marketStats, saveMarket, (err, result)->
      console.log result
      mongoose.connection.close()

task "trade:aggregate_last_stats", "Aggregate latest market stats", ()->
  require('./models/db_connect_mongo')
  TradeStats = require "./models/trade_stats"
  Order = require "./models/order"
  now = Date.now()
  tenMin = 600000
  endTime =  now - now % tenMin
  startTime = endTime - tenMin
  markets = {}
  Order.find({status: "completed", close_time: {$gte: startTime, $lte: endTime}}).sort({close_time: "asc"}).exec (err, orders)->
    for order in orders
      marketType = "#{order.buy_currency}_#{order.sell_currency}"
      if not markets[marketType]
        markets[marketType] = new TradeStats
          type: marketType
          start_time: startTime
          end_time: endTime
      markets[marketType].open_price = order.unit_price  if markets[marketType].open_price is 0
      markets[marketType].close_price = order.unit_price
      markets[marketType].high_price = order.unit_price  if order.unit_price > markets[marketType].high_price
      markets[marketType].low_price = order.unit_price  if order.unit_price < markets[marketType].low_price or markets[marketType].low_price is 0
      markets[marketType].volume += order.amount
    markets = _.values markets
    saveMarket = (market, cb)->
      market.save (err, mk)->
        return cb err  if err
        cb null, mk.id
    async.each markets, saveMarket, (err, result)->
      console.log "Aggregated trade data: ", result
      mongoose.connection.close()

task "test_sockets", "Send socket messages", ()->
  userSocket.send
    type: "test"
    eventData:
      a: 1
  setTimeout ()->
      userSocket.send
        type: "test"
        eventData:
          a: 1
    , 1000
  setTimeout ()->
      userSocket.send
        type: "test"
        eventData:
          a: 1
      userSocket.close()
    , 1000