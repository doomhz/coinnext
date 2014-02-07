(function() {
  var Order, TradeStats, async, restify, _;

  restify = require("restify");

  Order = require("../../models/order");

  TradeStats = require("../../models/trade_stats");

  async = require("async");

  _ = require("underscore");

  module.exports = function(app) {
    return app.post("/trade_stats", function(req, res, next) {
      var endTime, halfHour, markets, now, startTime;
      now = Date.now();
      halfHour = 1800000;
      endTime = now - now % halfHour;
      startTime = endTime - halfHour;
      markets = {};
      return Order.find({
        status: "completed",
        close_time: {
          $gte: startTime,
          $lte: endTime
        }
      }).sort({
        close_time: "asc"
      }).exec(function(err, orders) {
        var marketType, order, saveMarket, _i, _len;
        for (_i = 0, _len = orders.length; _i < _len; _i++) {
          order = orders[_i];
          marketType = "" + order.buy_currency + "_" + order.sell_currency;
          if (!markets[marketType]) {
            markets[marketType] = new TradeStats({
              type: marketType,
              start_time: startTime,
              end_time: endTime
            });
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
          markets[marketType].volume += order.amount;
        }
        markets = _.values(markets);
        saveMarket = function(market, cb) {
          return market.save(function(err, mk) {
            if (err) {
              return cb(err);
            }
            return cb(null, mk.id);
          });
        };
        return async.each(markets, saveMarket, function(err, result) {
          return res.send({
            message: "TRade stats aggregated from " + (new Date(startTime)) + " to " + (new Date(endTime)),
            result: result
          });
        });
      });
    });
  };

}).call(this);
