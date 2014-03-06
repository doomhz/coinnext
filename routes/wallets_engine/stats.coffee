restify = require "restify"
Order = require "../../models/order"
TradeStats = GLOBAL.db.TradeStats
_ = require "underscore"

module.exports = (app)->

  app.post "/trade_stats", (req, res, next)->
    now = Date.now()
    halfHour = 1800000
    endTime =  now - now % halfHour
    startTime = endTime - halfHour
    markets = {}
    Order.find({status: "completed", close_time: {$gte: startTime, $lte: endTime}}).sort({close_time: "asc"}).exec (err, orders)->
      for order in orders
        marketType = "#{order.buy_currency}_#{order.sell_currency}"
        if not markets[marketType]
          markets[marketType] =
            type: marketType
            start_time: startTime
            end_time: endTime
        markets[marketType].open_price = order.unit_price  if markets[marketType].open_price is 0
        markets[marketType].close_price = order.unit_price
        markets[marketType].high_price = order.unit_price  if order.unit_price > markets[marketType].high_price
        markets[marketType].low_price = order.unit_price  if order.unit_price < markets[marketType].low_price or markets[marketType].low_price is 0
        markets[marketType].volume += order.amount
      markets = _.values markets
      TradeStats.bulkCreate(markets).success (result)->
        res.send
          message: "Trade stats aggregated from #{new Date(startTime)} to #{new Date(endTime)}"
          result: result
