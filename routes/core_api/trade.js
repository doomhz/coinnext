(function() {
  var JsonRenderer, MarketHelper, MarketStats, Order, TradeHelper, Wallet, restify;

  restify = require("restify");

  Order = GLOBAL.db.Order;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  TradeHelper = require("../../lib/trade_helper");

  JsonRenderer = require("../../lib/json_renderer");

  MarketHelper = require("../../lib/market_helper");

  module.exports = function(app) {
    app.post("/publish_order", function(req, res, next) {
      var data, orderCurrency;
      data = req.body;
      data.in_queue = true;
      orderCurrency = data["" + data.action + "_currency"];
      return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
        if (!market) {
          return next(new restify.ConflictError("Market for " + orderCurrency + " is disabled."));
        }
        return TradeHelper.createOrder(data, function(err, newOrder) {
          var orderData;
          if (err) {
            return next(new restify.ConflictError(err));
          }
          orderData = {
            external_order_id: newOrder.id,
            type: newOrder.type,
            action: newOrder.action,
            buy_currency: MarketHelper.getCurrency(newOrder.buy_currency),
            sell_currency: MarketHelper.getCurrency(newOrder.sell_currency),
            amount: newOrder.amount,
            unit_price: newOrder.unit_price
          };
          return GLOBAL.queue.Event.addOrder(orderData, function(err) {
            if (err) {
              console.error("Could add add_order event for order " + newOrder.id + " - " + err);
              if (err) {
                return next(new restify.ConflictError("Could not submit order."));
              }
            }
            res.send({
              id: newOrder.id
            });
            return TradeHelper.pushOrderUpdate({
              type: "order-to-add",
              eventData: JsonRenderer.order(newOrder)
            });
          });
        });
      });
    });
    return app.del("/cancel_order/:order_id", function(req, res, next) {
      var orderId;
      orderId = req.params.order_id;
      return Order.findById(orderId, function(err, order) {
        var orderCurrency;
        if (err || !order || !order.canBeCanceled()) {
          return next(new restify.ConflictError(err));
        }
        orderCurrency = order["" + order.action + "_currency"];
        return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
          if (!market) {
            return next(new restify.ConflictError("" + (new Date()) + " - Will not process order " + orderId + ", the market for " + orderCurrency + " is disabled."));
          }
          return GLOBAL.db.sequelize.transaction(function(transaction) {
            return GLOBAL.queue.Event.addCancelOrder({
              order_id: orderId
            }, function(err) {
              if (err) {
                return transaction.rollback().success(function() {
                  return next(new restify.ConflictError("Could not cancel order " + orderId + " - " + err));
                });
              }
              order.in_queue = true;
              return order.save({
                transaction: transaction
              }).complete(function(err) {
                if (err) {
                  return transaction.rollback().success(function() {
                    return next(new restify.ConflictError("Could not set order " + orderId + " for canceling - " + err));
                  });
                }
                return transaction.commit().success(function() {
                  res.send({
                    id: orderId
                  });
                  return TradeHelper.pushOrderUpdate({
                    type: "order-to-cancel",
                    eventData: {
                      id: orderId
                    }
                  });
                });
              });
            });
          });
        });
      });
    });
  };

}).call(this);
