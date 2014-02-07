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