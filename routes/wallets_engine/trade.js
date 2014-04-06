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
    app.del("/cancel_order/:order_id", function(req, res, next) {
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
    return app.post("/orders_match", function(req, res, next) {
      var matchedData;
      matchedData = req.body;
      return Order.findById(matchedData[0].order_id, function(err, orderToMatch) {
        if (!orderToMatch || err) {
          return next(new restify.ConflictError("Wrong order to complete " + matchedData[0].order_id + " - " + err));
        }
        return Order.findById(matchedData[1].order_id, function(err, matchingOrder) {
          if (!matchingOrder || err) {
            return next(new restify.ConflictError("Wrong order to complete " + matchedData[1].order_id + " - " + err));
          }
          return GLOBAL.db.sequelize.transaction(function(transaction) {
            return TradeHelper.updateMatchedOrder(orderToMatch, matchedData[0], transaction, function(err, updatedOrderToMatch) {
              if (err) {
                console.error("Could not process order " + orderToMatch.id, err);
                return transaction.rollback().success(function() {
                  return next(new restify.ConflictError("Could not process order " + orderToMatch.id + " - " + err));
                });
              }
              return TradeHelper.updateMatchedOrder(matchingOrder, matchedData[1], transaction, function(err, updatedMatchingOrder) {
                if (err) {
                  console.error("Could not process order " + matchingOrder.id, err);
                  return transaction.rollback().success(function() {
                    return next(new restify.ConflictError("Could not process order " + matchingOrder.id + " - " + err));
                  });
                }
                transaction.commit().success(function() {
                  TradeHelper.trackMatchedOrder(updatedOrderToMatch);
                  TradeHelper.trackMatchedOrder(updatedMatchingOrder);
                  return res.send();
                });
                return transaction.done(function(err) {
                  if (err) {
                    return next(new restify.ConflictError("Could not process order " + orderId + " - " + err));
                  }
                });
              });
            });
          });
        });
      });
    });
  };

}).call(this);
