(function() {
  var ClientSocket, JsonRenderer, MarketHelper, MarketStats, Order, TradeQueue, Wallet, orderSocket, restify, trader;

  restify = require("restify");

  Order = GLOBAL.db.Order;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  TradeQueue = require("../../lib/trade_queue");

  trader = null;

  JsonRenderer = require("../../lib/json_renderer");

  MarketHelper = require("../../lib/market_helper");

  ClientSocket = require("../../lib/client_socket");

  orderSocket = new ClientSocket({
    host: GLOBAL.appConfig().app_host,
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
        trader.publishOrder(queueData, function(queueError, response) {
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
          return orderSocket.send({
            type: "order-published",
            eventData: JsonRenderer.order(order)
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
            orderId: order.id
          }
        };
        trader.publishOrder(queueData, function(queueError, response) {
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
                  return orderSocket.send({
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
    onOrderCompleted = function(message) {
      var fee, orderId, receivedAmount, result, soldAmount, status, unitPrice;
      result = null;
      try {
        result = JSON.parse(message.data.toString());
      } catch (_error) {}
      if (result && result.eventType === "orderResult") {
        orderId = result.data.orderId;
        status = result.data.orderState;
        soldAmount = MarketHelper.convertFromBigint(result.data.soldAmount);
        receivedAmount = MarketHelper.convertFromBigint(result.data.receivedAmount);
        fee = MarketHelper.convertFromBigint(result.data.orderFee);
        unitPrice = MarketHelper.convertFromBigint(result.data.orderPPU);
        return Order.findById(orderId, function(err, order) {
          if (!order) {
            return console.error("Wrong order to complete ", result);
          }
          return Wallet.findUserWalletByCurrency(order.user_id, order.buy_currency, function(err, buyWallet) {
            return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, sellWallet) {
              return GLOBAL.db.sequelize.transaction(function(transaction) {
                return sellWallet.addHoldBalance(-soldAmount, transaction, function(err, sellWallet) {
                  if (err || !sellWallet) {
                    return transaction.rollback().success(function() {
                      return next(new restify.ConflictError("Could not complete order " + orderId + " - " + err));
                    });
                  }
                  return buyWallet.addBalance(receivedAmount, transaction, function(err, buyWallet) {
                    if (err || !buyWallet) {
                      return transaction.rollback().success(function() {
                        return next(new restify.ConflictError("Could not complete order " + orderId + " - " + err));
                      });
                    }
                    order.status = status;
                    order.sold_amount += soldAmount;
                    order.result_amount += receivedAmount;
                    order.fee = fee;
                    order.unit_price = unitPrice;
                    if (status === "completed") {
                      order.close_time = Date.now();
                    }
                    return order.save({
                      transaction: transaction
                    }).complete(function(err, order) {
                      if (err) {
                        return console.error("Could not process order ", result, err);
                      }
                      if (err) {
                        return transaction.rollback().success(function() {
                          return next(new restify.ConflictError("Could not process order " + orderId + " - " + err));
                        });
                      }
                      transaction.commit().success(function() {
                        if (order.status === "completed") {
                          MarketStats.trackFromOrder(order, function(err, mkSt) {
                            return orderSocket.send({
                              type: "market-stats-updated",
                              eventData: mkSt.toJSON()
                            });
                          });
                          orderSocket.send({
                            type: "order-completed",
                            eventData: JsonRenderer.order(order)
                          });
                        }
                        if (order.status === "partiallyCompleted") {
                          orderSocket.send({
                            type: "order-partially-completed",
                            eventData: JsonRenderer.order(order)
                          });
                        }
                        return console.log("Processed order " + order.id + " ", result);
                      });
                      return transaction.done(function(err) {
                        return next(new restify.ConflictError("Could not process order " + orderId + " - " + err));
                      });
                    });
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
