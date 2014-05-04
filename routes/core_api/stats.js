(function() {
  var MarketHelper, Order, TradeStats, math, restify, _;

  restify = require("restify");

  Order = GLOBAL.db.Order;

  TradeStats = GLOBAL.db.TradeStats;

  MarketHelper = require("../../lib/market_helper");

  _ = require("underscore");

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  module.exports = function(app) {
    return app.post("/trade_stats", function(req, res, next) {
      var endTime, halfHour, markets, now, startTime;
      now = Date.now();
      halfHour = 1800000;
      endTime = now - now % halfHour;
      startTime = endTime - halfHour;
      markets = {};
      return Order.findCompletedByTimeAndAction(startTime, endTime, "sell", function(err, orders) {
        var marketType, order, _i, _len;
        for (_i = 0, _len = orders.length; _i < _len; _i++) {
          order = orders[_i];
          marketType = "" + order.sell_currency + "_" + order.buy_currency;
          if (!markets[marketType]) {
            markets[marketType] = {
              type: marketType,
              start_time: startTime,
              end_time: endTime,
              open_price: 0,
              high_price: 0,
              low_price: 0,
              volume: 0
            };
          }
          if (markets[marketType].open_price === 0) {
            markets[marketType].open_price = order.unit_price;
          }
          markets[marketType].close_price = order.unit_price;
          if (order.unit_price > markets[marketType].high_price) {
            markets[marketType].high_price = order.unit_price;
          }
          if (order.unit_price < markets[marketType].low_price || markets[marketType].low_price === 0) {
            markets[marketType].low_price = order.unit_price;
          }
          markets[marketType].volume = math.add(markets[marketType].volume, order.amount);
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
