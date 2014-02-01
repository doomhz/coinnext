(function() {
  var MarketStats, Order, TradeQueue, Wallet, restify, trader;

  restify = require("restify");

  Order = require("../../models/order");

  Wallet = require("../../models/wallet");

  MarketStats = require("../../models/market_stats");

  TradeQueue = require("../../lib/trade_queue");

  trader = null;

  module.exports = function(app) {
    var onOrderCompleted, tq;
    app.post("/publish_order/:order_id", function(req, res, next) {
      var orderId;
      orderId = req.params.order_id;
      console.log(orderId);
      return Order.findById(orderId, function(err, order) {
        var amount, marketType, orderCurrency, queueData, unitPrice;
        if (err) {
          return next(new restify.ConflictError(err));
        }
        if (!trader) {
          return next(new restify.ConflictError("Trade queue down"));
        }
        marketType = ("" + order.action + "_" + order.type).toUpperCase();
        orderCurrency = order["" + order.action + "_currency"];
        amount = order.amount * 100000000;
        unitPrice = order.unit_price ? order.unit_price * 100000000 : order.unit_price;
        queueData = {
          eventType: "order",
          data: {
            orderId: order.engine_id,
            orderType: marketType,
            orderAmount: amount,
            orderCurrency: orderCurrency,
            orderLimitPrice: unitPrice
          }
        };
        trader.publishOrder(queueData, function(queueError, response) {
          return console.log(arguments);
        });
        return Order.update({
          _id: orderId
        }, {
          published: true
        }, function(err, result) {
          if (!err) {
            return res.send({
              id: orderId,
              published: true
            });
          } else {
            return next(new restify.ConflictError(err));
          }
        });
      });
    });
    onOrderCompleted = function(message) {
      var engineId, receivedAmount, result, soldAmount, status;
      result = null;
      try {
        result = JSON.parse(message.data.toString());
      } catch (_error) {}
      if (result && result.eventType === "orderResult") {
        engineId = result.data.orderId;
        status = result.data.orderState;
        soldAmount = parseFloat(result.data.soldAmount) / 100000000;
        receivedAmount = parseFloat(result.data.receivedAmount) / 100000000;
        return Order.findByEngineId(engineId, function(err, order) {
          if (order) {
            return Wallet.findUserWalletByCurrency(order.user_id, order.buy_currency, function(err, buyWallet) {
              return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, sellWallet) {
                return sellWallet.holdBalance(-soldAmount, function(err, sellWallet) {
                  return buyWallet.addBalance(receivedAmount, function(err, buyWallet) {
                    order.status = status;
                    order.result_amount = receivedAmount;
                    return order.save(function(err, order) {
                      if (err) {
                        return console.error("Could not process order ", result, err);
                      }
                      if (order.status === "completed") {
                        MarketStats.trackFromOrder(order);
                      }
                      return console.log("Processed order " + order.id + " ", result);
                    });
                  });
                });
              });
            });
          } else {
            return console.error("Wrong order to complete ", result);
          }
        });
      }
    };
    tq = new TradeQueue({
      connection: GLOBAL.appConfig().amqp.connection,
      openOrdersQueueName: GLOBAL.appConfig().amqp.queues.open_orders,
      completedOrdersQueueName: GLOBAL.appConfig().amqp.queues.completed_orders,
      onComplete: onOrderCompleted,
      onConnect: function(tradeQueue) {
        return trader = tradeQueue;
      }
    });
    return tq.connect();
  };

}).call(this);
