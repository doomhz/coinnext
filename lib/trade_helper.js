(function() {
  var ClientSocket, JsonRenderer, MarketHelper, MarketStats, Order, TradeHelper, TradeQueue, Wallet, exports, orderSocket, restify;

  restify = require("restify");

  Order = GLOBAL.db.Order;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  TradeQueue = require("./trade_queue");

  JsonRenderer = require("./json_renderer");

  MarketHelper = require("./market_helper");

  ClientSocket = require("./client_socket");

  orderSocket = new ClientSocket({
    host: GLOBAL.appConfig().app_host,
    path: "orders"
  });

  TradeHelper = {
    trader: null,
    pushOrderUpdate: function(data) {
      return orderSocket.send(data);
    },
    initQueue: function() {
      var tq;
      tq = new TradeQueue({
        connection: GLOBAL.appConfig().amqp.connection,
        openOrdersQueueName: GLOBAL.appConfig().amqp.queues.open_orders,
        completedOrdersQueueName: GLOBAL.appConfig().amqp.queues.completed_orders,
        onComplete: TradeHelper.onOrderCompleted,
        onConnect: function(tradeQueue) {
          return TradeHelper.trader = tradeQueue;
        }
      });
      return tq.connect();
    },
    onOrderCompleted: function(message) {
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
    }
  };

  exports = module.exports = TradeHelper;

}).call(this);
