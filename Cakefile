fs = require "fs"
environment = process.env.NODE_ENV or 'development'
config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', 'utf8'))[environment]
GLOBAL.appConfig = ()-> config
GLOBAL.db = require './models/index'

task "db:create_tables", "Create all tables", ()->
  GLOBAL.db.sequelize.sync().complete ()->

task "db:create_tables_force", "Drop and create all tables", ()->
  return console.log "Not in production!"  if environment is "production"
  GLOBAL.db.sequelize.sync({force: true}).complete ()->

task "db:seed_market_stats", "Seed default market stats", ()->
  MarketStats = GLOBAL.db.MarketStats
  marketStats = require './models/seeds/market_stats'
  GLOBAL.db.sequelize.query("TRUNCATE TABLE #{MarketStats.tableName}").complete ()->
    MarketStats.bulkCreate(marketStats).success ()->
      MarketStats.findAll().success (result)->
        console.log JSON.stringify result

task "db:seed_trade_stats", "Seed default trade stats", ()->
  TradeStats = GLOBAL.db.TradeStats
  tradeStats = require './models/seeds/trade_stats'
  now = Date.now()
  halfHour = 1800000
  oneDay = 86400000
  endTime =  now - now % halfHour
  startTime = endTime - oneDay
  startTimes =
    LTC_BTC: startTime
    PPC_BTC: startTime
  for stat in tradeStats
    stat.start_time = startTimes[stat.type]
    stat.end_time = stat.start_time + halfHour
    startTimes[stat.type] = stat.end_time
  GLOBAL.db.sequelize.query("TRUNCATE TABLE #{TradeStats.tableName}").complete ()->
    TradeStats.bulkCreate(tradeStats).success ()->
      TradeStats.findAll().success (result)->
        console.log JSON.stringify result

option "-e", "--email [EMAIL]", "User email"
option "-p", "--pass [PASS]", "User pass"
task "admin:generate_user", "Add new admin user -e -p", (opts)->
  data =
    email: opts.email
    password: opts.pass
  GLOBAL.db.AdminUser.createNewUser data, (err, newUser)->
    return console.error err  if err
    newUser.generateGAuthData (data, newUser)->
      console.log data.google_auth_qr
      console.log newUser.gauth_key
    