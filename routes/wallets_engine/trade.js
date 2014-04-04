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
    app.post("/publish_order/:order_id", function(req, res, next) {
      var orderId;
      orderId = req.params.order_id;
      return Order.findById(orderId, function(err, order) {
        var orderCurrency;
        if (err) {
          return next(new restify.ConflictError(err));
        }
        orderCurrency = order["" + order.action + "_currency"];
        return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
          if (!market) {
            return next(new restify.ConflictError("" + (new Date()) + " - Will not process order " + orderId + ", the market for " + orderCurrency + " is disabled."));
          }
          return TradeHelper.submitOrder(order, function(err) {
            if (err) {
              return next(new restify.ConflictError(err));
            }
            order.published = true;
            return order.save().complete(function(err, order) {
              if (err) {
                return next(new restify.ConflictError(err));
              }
              res.send({
                id: orderId,
                published: true
              });
              return TradeHelper.pushOrderUpdate({
                type: "order-published",
                eventData: JsonRenderer.order(order)
              });
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
        if (err || !order) {
          return next(new restify.ConflictError(err));
        }
        orderCurrency = order["" + order.action + "_currency"];
        return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
          if (!market) {
            return next(new restify.ConflictError("" + (new Date()) + " - Will not process order " + orderId + ", the market for " + orderCurrency + " is disabled."));
          }
          return TradeHelper.cancelOrder(order, function(err) {
            if (err) {
              return next(new restify.ConflictError(err));
            }
            return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, wallet) {
              return GLOBAL.db.sequelize.transaction(function(transaction) {
                return wallet.holdBalance(-order.left_hold_balance, transaction, function(err, wallet) {
                  if (err || !wallet) {
                    return transaction.rollback().success(function() {
                      return next(new restify.ConflictError("Could not cancel order " + orderId + " - " + err));
                    });
                  }
                  return order.destroy({
                    transaction: transaction
                  }).complete(function(err) {
                    if (err) {
                      return transaction.rollback().success(function() {
                        return next(new restify.ConflictError(err));
                      });
                    }
                    transaction.commit().success(function() {
                      res.send({
                        id: orderId,
                        canceled: true
                      });
                      return TradeHelper.pushOrderUpdate({
                        type: "order-canceled",
                        eventData: {
                          id: orderId
                        }
                      });
                    });
                    return transaction.done(function(err) {
                      if (err) {
                        return next(new restify.ConflictError("Could not cancel order " + orderId + " - " + err));
                      }
                    });
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
