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

task "db:seed_trade_stats", "Seed default trade stats", ()->
  require('./models/db_connect_mongo')
  TradeStats = require "./models/trade_stats"
  TradeStats.collection.drop (err) ->
    tradeStats = [
      {type: "LTC_BTC", open_price: 0.02599, close_price: 0.0262, high_price: 0.02999, low_price: 0.02199, volume: 2182.1902072}
      {type: "LTC_BTC", open_price: 0.0262, close_price: 0.0282, high_price: 0.031, low_price: 0.0199, volume: 3178.1902072}
      {type: "LTC_BTC", open_price: 0.0282, close_price: 0.0142, high_price: 0.0299, low_price: 0.0159, volume: 5678.1902072}
      
      {type: "PPC_BTC", open_price: 0.00664, close_price: 0.00665, high_price: 0.00666, low_price: 0.00664, volume: 232.1904831}
      {type: "PPC_BTC", open_price: 0.00665, close_price: 0.00713, high_price: 0.00865, low_price: 0.00564, volume: 567.1904831}
      {type: "PPC_BTC", open_price: 0.00713, close_price: 0.00508, high_price: 0.00899, low_price: 0.00264, volume: 827.1904831}
    ]
    now = Date.now()
    halfHour = 1800000
    oneDay = 86400000
    endTime =  now - now % halfHour
    startTime = endTime - oneDay
    startTimes =
      LTC_BTC: startTime
      PPC_BTC: startTime
    saveStats = (st, cb)->
      st.start_time = startTimes[st.type]
      st.end_time = st.start_time + halfHour
      startTimes[st.type] = st.end_time
      TradeStats.create st, cb
    async.mapSeries tradeStats, saveStats, (err, result)->
      console.log result
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