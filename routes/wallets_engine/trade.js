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
      console.log(orderId);
      return Order.findById(orderId, function(err, order) {
        var marketType, orderCurrency;
        if (err) {
          return next(new restify.ConflictError(err));
        }
        if (!TradeHelper.trader) {
          return next(new restify.ConflictError("Trade queue down"));
        }
        marketType = ("" + order.action + "_" + order.type).toUpperCase();
        orderCurrency = order["" + order.action + "_currency"];
        return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
          var amount, queueData, unitPrice;
          if (!market) {
            return next(new restify.ConflictError("" + (new Date()) + " - Will not process order " + orderId + ", the market for " + orderCurrency + " is disabled."));
          }
          amount = MarketHelper.convertToBigint(order.amount);
          unitPrice = order.unit_price ? MarketHelper.convertToBigint(order.unit_price) : order.unit_price;
          queueData = {
            eventType: "order",
            data: {
              orderId: order.id,
              orderType: marketType,
              orderAmount: amount,
              orderCurrency: orderCurrency,
              orderLimitPrice: unitPrice
            }
          };
          TradeHelper.trader.publishOrder(queueData, function(queueError, response) {
            return console.log(arguments);
          });
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
    app.del("/cancel_order/:order_id", function(req, res, next) {
      var orderId;
      orderId = req.params.order_id;
      console.log(orderId);
      return Order.findById(orderId, function(err, order) {
        var orderCurrency;
        if (err) {
          return next(new restify.ConflictError(err));
        }
        if (!TradeHelper.trader) {
          return next(new restify.ConflictError("Trade queue down"));
        }
        orderCurrency = order["" + order.action + "_currency"];
        return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
          var queueData;
          if (!market) {
            return next(new restify.ConflictError("" + (new Date()) + " - Will not process order " + orderId + ", the market for " + orderCurrency + " is disabled."));
          }
          queueData = {
            eventType: "event",
            data: {
              action: "cancelOrder",
              orderId: order.id
            }
          };
          TradeHelper.trader.publishOrder(queueData, function(queueError, response) {
            return console.log(arguments);
          });
          return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, wallet) {
            var remainingHoldBalance;
            remainingHoldBalance = order.amount - order.sold_amount;
            return GLOBAL.db.sequelize.transaction(function(transaction) {
              return wallet.holdBalance(-remainingHoldBalance, transaction, function(err, wallet) {
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
                    return next(new restify.ConflictError("Could not cancel order " + orderId + " - " + err));
                  });
                });
              });
            });
          });
        });
      });
    });
    return TradeHelper.initQueue();
  };

}).call(this);
