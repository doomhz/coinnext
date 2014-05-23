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
      orderCurrency = data["" + data.action + "_currency"];
      return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
        if (!market) {
          return next(new restify.ConflictError("Market for " + orderCurrency + " is disabled."));
        }
        return TradeHelper.createOrder(data, function(err, newOrder) {
          if (err) {
            return next(new restify.ConflictError(err));
          }
          return TradeHelper.submitOrder(newOrder, function(err) {
            if (err) {
              console.error("Could not publish the order " + newOrder.id + " - " + err);
              return res.send({
                id: newOrder.id,
                published: false
              });
            }
            newOrder.published = true;
            return newOrder.save().complete(function(err, newOrder) {
              if (err) {
                console.error("Could not set order " + newOrder.id + " to published - " + err);
              }
              res.send({
                id: newOrder.id,
                published: newOrder.published
              });
              return TradeHelper.pushOrderUpdate({
                type: "order-published",
                eventData: JsonRenderer.order(newOrder)
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
                      TradeHelper.pushOrderUpdate({
                        type: "order-canceled",
                        eventData: {
                          id: orderId
                        }
                      });
                      return TradeHelper.pushUserUpdate({
                        type: "wallet-balance-changed",
                        user_id: wallet.user_id,
                        eventData: JsonRenderer.wallet(wallet)
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
