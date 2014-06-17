(function() {
  var MarketHelper, OrderLog, TradeStats, math, _;

  OrderLog = GLOBAL.db.OrderLog;

  TradeStats = GLOBAL.db.TradeStats;

  MarketHelper = require("../../lib/market_helper");

  math = require("../../lib/math");

  _ = require("underscore");

  module.exports = function(app) {
    return app.post("/trade_stats", function(req, res, next) {
      var endTime, halfHour, markets, now, startTime;
      now = Date.now();
      halfHour = 1800000;
      endTime = now - now % halfHour;
      startTime = endTime - halfHour;
      markets = {};
      return OrderLog.findByTimeAndAction(startTime, endTime, "sell", function(err, orderLogs) {
        var marketType, orderLog, _i, _len;
        for (_i = 0, _len = orderLogs.length; _i < _len; _i++) {
          orderLog = orderLogs[_i];
          marketType = "" + orderLog.order.sell_currency + "_" + orderLog.order.buy_currency;
          if (!markets[marketType]) {
            markets[marketType] = {
              type: marketType,
              start_time: startTime,
              end_time: endTime,
              open_price: 0,
              high_price: 0,
              low_price: 0,
              volume: 0,
              exchange_volume: 0
            };
          }
          if (markets[marketType].open_price === 0) {
            markets[marketType].open_price = orderLog.unit_price;
          }
          markets[marketType].close_price = orderLog.unit_price;
          if (orderLog.unit_price > markets[marketType].high_price) {
            markets[marketType].high_price = orderLog.unit_price;
          }
          if (orderLog.unit_price < markets[marketType].low_price || markets[marketType].low_price === 0) {
            markets[marketType].low_price = orderLog.unit_price;
          }
          markets[marketType].volume = parseInt(math.add(MarketHelper.toBignum(markets[marketType].volume), MarketHelper.toBignum(orderLog.matched_amount)));
          markets[marketType].exchange_volume = parseInt(math.add(MarketHelper.toBignum(markets[marketType].exchange_volume), MarketHelper.toBignum(orderLog.result_amount)));
        }
        markets = _.values(markets);
        return TradeStats.bulkCreate(markets).complete(function(err, result) {
          return res.send({
            message: "Trade stats aggregated from " + (new Date(startTime)) + " to " + (new Date(endTime)),
            result: result
          });
        });
      });
    });
  };

}).call(this);
