(function() {
  var JsonRenderer, MarketHelper, MarketStats, Order, Wallet, _;

  Order = GLOBAL.db.Order;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  MarketHelper = require("../lib/market_helper");

  JsonRenderer = require("../lib/json_renderer");

  _ = require("underscore");

  module.exports = function(app) {
    app.post("/orders", function(req, res) {
      var data, errors, newOrder;
      if (!req.user) {
        return JsonRenderer.error("You need to be logged in to place an order.", res);
      }
      if (!req.user.canTrade()) {
        return JsonRenderer.error("Sorry, but you can not trade. Did you verify your account?", res);
      }
      data = req.body;
      data.user_id = req.user.id;
      data.status = "open";
      data.amount = parseFloat(data.amount);
      if (_.isNumber(data.amount) && !_.isNaN(data.amount) && _.isFinite(data.amount)) {
        data.amount = MarketHelper.toBigint(data.amount);
      }
      data.unit_price = parseFloat(data.unit_price);
      if (_.isNumber(data.unit_price) && !_.isNaN(data.unit_price) && _.isFinite(data.unit_price)) {
        data.unit_price = MarketHelper.toBigint(data.unit_price);
      }
      newOrder = Order.build(data);
      errors = newOrder.validate();
      if (errors) {
        return JsonRenderer.error(errors, res);
      }
      return newOrder.publish(function(err, order) {
        if (err) {
          return JsonRenderer.error(err, res);
        }
        return res.json(JsonRenderer.order(order));
      });
    });
    app.get("/orders", function(req, res) {
      if (req.query.user_id != null) {
        if (req.user) {
          req.query.user_id = req.user.id;
        }
        if (!req.user) {
          req.query.user_id = 0;
        }
      }
      return Order.findByOptions(req.query, function(err, orders) {
        if (err) {
          return JsonRenderer.error("Sorry, could not get open orders...", res);
        }
        return res.json(JsonRenderer.orders(orders));
      });
    });
    return app.del("/orders/:id", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error("You need to be logged in to delete an order.", res);
      }
      return Order.findByUserAndId(req.params.id, req.user.id, function(err, order) {
        if (err || !order) {
          return JsonRenderer.error("Sorry, could not delete orders...", res);
        }
        return order.cancel(function(err) {
          if (err) {
            console.error("Could not cancel order - " + err);
          }
          if (err) {
            return res.json(JsonRenderer.order(order));
          }
          return res.json({});
        });
      });
    });
  };

}).call(this);
