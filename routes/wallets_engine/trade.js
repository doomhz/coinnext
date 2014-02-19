(function() {
  var ClientSocket, MarketStats, Order, TradeQueue, Wallet, orderSocket, restify, trader;

  restify = require("restify");

  Order = require("../../models/order");

  Wallet = require("../../models/wallet");

  MarketStats = require("../../models/market_stats");

  TradeQueue = require("../../lib/trade_queue");

  trader = null;

  ClientSocket = require("../../lib/client_socket");

  orderSocket = new ClientSocket({
    host: GLOBAL.appConfig().users.hostname,
    path: "orders"
  });

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
        order.published = true;
        return order.save(function(err, order) {
          if (err) {
            return next(new restify.ConflictError(err));
          }
          res.send({
            id: orderId,
            published: true
          });
          return orderSocket.send({
            type: "order-published",
            eventData: order.toJSON()
          });
        });
      });
    });
    app.del("/cancel_order/:order_id", function(req, res, next) {
      var orderId;
      orderId = req.params.order_id;
      console.log(orderId);
      return Order.findById(orderId, function(err, order) {
        var queueData;
        if (err) {
          return next(new restify.ConflictError(err));
        }
        if (!trader) {
          return next(new restify.ConflictError("Trade queue down"));
        }
        queueData = {
          eventType: "event",
          data: {
            action: "cancelOrder",
            orderId: order.engine_id
          }
        };
        trader.publishOrder(queueData, function(queueError, response) {
          return console.log(arguments);
        });
        return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, wallet) {
          return wallet.holdBalance(-order.amount, function(err, wallet) {
            return order.remove(function(err) {
              if (err) {
                return next(new restify.ConflictError(err));
              }
              res.send({
                id: orderId,
                canceled: true
              });
              return orderSocket.send({
                type: "order-canceled",
                eventData: {
                  id: orderId
                }
              });
            });
          });
        });
      });
    });
    setInterval(function() {
      orderSocket.send({
        type: "order-test-external",
        eventData: {
          a: 1
        }
      });
      return console.log("sent");
    }, 3000);
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
          if (!order) {
            return console.error("Wrong order to complete ", result);
          }
          return Wallet.findUserWalletByCurrency(order.user_id, order.buy_currency, function(err, buyWallet) {
            return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, sellWallet) {
              return sellWallet.holdBalance(-soldAmount, function(err, sellWallet) {
                return buyWallet.addBalance(receivedAmount, function(err, buyWallet) {
                  order.status = status;
                  order.sold_amount += soldAmount;
                  order.result_amount += receivedAmount;
                  if (status === "completed") {
                    order.close_time = Date.now();
                  }
                  return order.save(function(err, order) {
                    if (err) {
                      return console.error("Could not process order ", result, err);
                    }
                    if (order.status === "completed") {
                      MarketStats.trackFromOrder(order, function(err, mkSt) {
                        return orderSocket.send({
                          type: "market-stats-updated",
                          eventData: mkSt.toJSON()
                        });
                      });
                      orderSocket.send({
                        type: "order-completed",
                        eventData: order.toJSON()
                      });
                    }
                    return console.log("Processed order " + order.id + " ", result);
                  });
                });
              });
            });
          });
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
