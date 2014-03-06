fs = require "fs"
environment = process.env.NODE_ENV or 'development'
config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', 'utf8'))[environment]
GLOBAL.appConfig = ()-> config
async = require "async"
_ = require "underscore"

task "db:ensure_indexes", "Create indexes for all the collections", ()->
  require('./models/db_connect_mongo')
  GLOBAL.db = require './models/mysql/index'
  GLOBAL.db.sequelize.sync({force: true}).complete ()->
  _s         = require "underscore.string"
  modelNames = [
    "User", "Order", "Payment",
    "Transaction", "Wallet"
  ]
  for modelName in modelNames
    model = require "./models/#{_s.underscored(modelName)}"
    model.ensureIndexes()

task "db:seed_market_stats", "Seed default market stats", ()->
  GLOBAL.db = require './models/mysql/index'
  MarketStats = GLOBAL.db.MarketStats
  marketStats = require './models/seeds/market_stats'
  GLOBAL.db.sequelize.query("TRUNCATE TABLE #{MarketStats.tableName}").complete ()->
    MarketStats.bulkCreate(marketStats).success ()->
      MarketStats.findAll().success (result)->
        console.log result

task "db:seed_trade_stats", "Seed default trade stats", ()->
  require('./models/db_connect_mongo')
  TradeStats = require "./models/trade_stats"
  tradeStats = require './models/seeds/trade_stats'
  TradeStats.collection.drop (err) ->
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
  JsonRenderer = require "./lib/json_renderer"
  ClientSocket = require "./lib/client_socket"
  usersSocket = new ClientSocket
    host: GLOBAL.appConfig().app_host
    path: "users"
  require('./models/db_connect_mongo')
  Wallet = require "./models/wallet"
  Wallet.findById "52c2f94d83c42a0000000001", (err, wallet)->
    wallet.balance = 10
    wallet.hold_balance = 15
    usersSocket.send
      type: "wallet-balance-loaded"
      user_id: wallet.user_id
      eventData: JsonRenderer.wallet wallet
    setTimeout ()->
        usersSocket.close()
        mongoose.connection.close()
      , 1000
  ###
  orderSocket = new ClientSocket
    host: GLOBAL.appConfig().app_host
    path: "orders"
  require('./models/db_connect_mongo')
  Order = require "./models/order"
  Order.findById "5308a9944a49327ab9ba0b2b", (err, order)->
    order.status = "partiallyCompleted"
    order.unit_price = 0.1
    order.sold_amount = 5
    order.result_amount = 0.5
    orderSocket.send
      type: "order-partially-completed"
      eventData: JsonRenderer.order order
    setTimeout ()->
        orderSocket.close()
        mongoose.connection.close()
      , 1000
  ###