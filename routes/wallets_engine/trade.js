(function() {
  var Order, TradeQueue, Wallet, restify;

  restify = require("restify");

  Order = require("../../models/order");

  Wallet = require("../../models/wallet");

  TradeQueue = require("../../lib/trade_queue");

  module.exports = function(app) {
    var onOrderCompleted, tq, trader;
    trader = null;
    app.post("/publish_order/:order_id", function(req, res, next) {
      var orderId;
      orderId = req.params.order_id;
      console.log(orderId);
      return Order.findById(orderId, function(err, order) {
        var marketType, orderCurrency, queueData;
        if (err) {
          return next(new restify.ConflictError(err));
        }
        if (!trader) {
          return next(new restify.ConflictError("Trade queue down"));
        }
        marketType = ("" + order.action + "_" + order.type).toUpperCase();
        orderCurrency = order["" + order.action + "_currency"];
        queueData = {
          eventType: "order",
          eventUserId: order.user_id,
          data: {
            orderId: orderId,
            orderType: marketType,
            orderAmount: order.amount,
            orderCurrency: orderCurrency,
            orderLimitPrice: order.unit_price
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
    onOrderCompleted = function(result) {
      var orderId, receivedAmount, soldAmount, status;
      if (result.eventType === "orderResult") {
        orderId = result.data.orderId;
        status = result.data.orderState;
        soldAmount = result.data.soldAmount;
        receivedAmount = result.data.receivedAmount;
        return Order.findById(orderId, function(err, order) {
          if (order) {
            return Wallet.findUserWalletByCurrency(order.user_id, order.buy_currency, function(err, buyWallet) {
              return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, sellWallet) {
                return sellWallet.holdBalance(-soldAmount, function(err, sellWallet) {
                  return buyWallet.addBalance(receivedAmount, function(err, buyWallet) {
                    return Order.update({
                      _id: orderId
                    }, {
                      status: status
                    }, function(err, res) {
                      if (err) {
                        return console.error("Could not complete order " + result + " - " + err);
                      }
                    });
                  });
                });
              });
            });
          } else {
            return console.error("Wrong order to complete - " + result);
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
