restify = require "restify"
Order = GLOBAL.db.Order
TradeStats = GLOBAL.db.TradeStats
MarketHelper = require "../../lib/market_helper"
_ = require "underscore"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

module.exports = (app)->

  app.post "/trade_stats", (req, res, next)->
    now = Date.now()
    halfHour = 1800000
    endTime =  now - now % halfHour
    startTime = endTime - halfHour
    markets = {}
    Order.findCompletedByTimeAndAction startTime, endTime, "sell", (err, orders)->
      for order in orders
        marketType = "#{order.sell_currency}_#{order.buy_currency}"
        if not markets[marketType]
          markets[marketType] =
            type: marketType
            start_time: startTime
            end_time: endTime
            open_price: 0
            high_price: 0
            low_price: 0
            volume: 0
        markets[marketType].open_price = order.unit_price  if markets[marketType].open_price is 0
        markets[marketType].close_price = order.unit_price
        markets[marketType].high_price = order.unit_price  if order.unit_price > markets[marketType].high_price
        markets[marketType].low_price = order.unit_price  if order.unit_price < markets[marketType].low_price or markets[marketType].low_price is 0
        markets[marketType].volume = math.add markets[marketType].volume, order.amount
      markets = _.values markets
      TradeStats.bulkCreate(markets).complete (err, result)->
        res.send
          message: "Trade stats aggregated from #{new Date(startTime)} to #{new Date(endTime)}"
          result: result
