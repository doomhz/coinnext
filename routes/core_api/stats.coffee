OrderLog = GLOBAL.db.OrderLog
TradeStats = GLOBAL.db.TradeStats
MarketHelper = require "../../lib/market_helper"
math = require "../../lib/math"
_ = require "underscore"

module.exports = (app)->

  app.post "/trade_stats", (req, res, next)->
    now = Date.now()
    halfHour = 1800000
    endTime =  now - now % halfHour
    startTime = endTime - halfHour
    markets = {}
    OrderLog.findByTimeAndAction startTime, endTime, "sell", (err, orderLogs)->
      for orderLog in orderLogs
        marketType = "#{orderLog.order.sell_currency}_#{orderLog.order.buy_currency}"
        if not markets[marketType]
          markets[marketType] =
            type: marketType
            start_time: startTime
            end_time: endTime
            open_price: 0
            high_price: 0
            low_price: 0
            volume: 0
            exchange_volume: 0
        markets[marketType].open_price = orderLog.unit_price  if markets[marketType].open_price is 0
        markets[marketType].close_price = orderLog.unit_price
        markets[marketType].high_price = orderLog.unit_price  if orderLog.unit_price > markets[marketType].high_price
        markets[marketType].low_price = orderLog.unit_price  if orderLog.unit_price < markets[marketType].low_price or markets[marketType].low_price is 0
        markets[marketType].volume = parseInt math.add(MarketHelper.toBignum(markets[marketType].volume), MarketHelper.toBignum(orderLog.matched_amount))
        markets[marketType].exchange_volume = parseInt math.add(MarketHelper.toBignum(markets[marketType].exchange_volume), MarketHelper.toBignum(orderLog.result_amount))
      markets = _.values markets
      TradeStats.bulkCreate(markets).complete (err, result)->
        res.send
          message: "Trade stats aggregated from #{new Date(startTime)} to #{new Date(endTime)}"
          result: result
