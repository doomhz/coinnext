(function() {
  var ClientSocket, JsonRenderer, MarketHelper, MarketStats, Order, OrderLog, TradeHelper, Wallet, exports, math, orderSocket, usersSocket;

  Order = GLOBAL.db.Order;

  OrderLog = GLOBAL.db.OrderLog;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  MarketHelper = require("./market_helper");

  JsonRenderer = require("./json_renderer");

  MarketHelper = require("./market_helper");

  ClientSocket = require("./client_socket");

  orderSocket = new ClientSocket({
    namespace: "orders",
    redis: GLOBAL.appConfig().redis
  });

  usersSocket = new ClientSocket({
    namespace: "users",
    redis: GLOBAL.appConfig().redis
  });

  math = require("./math");

  TradeHelper = {
    createOrder: function(data, callback) {
      var holdBalance;
      if (callback == null) {
        callback = function() {};
      }
      if (data.type === "limit" && data.action === "buy") {
        holdBalance = MarketHelper.multiplyBigints(data.amount, data.unit_price);
      }
      if (data.type === "limit" && data.action === "sell") {
        holdBalance = data.amount;
      }
      return Wallet.findOrCreateUserWalletByCurrency(data.user_id, data.buy_currency, function(err, buyWallet) {
        if (err || !buyWallet) {
          return callback("Wallet " + data.buy_currency + " does not exist.");
        }
        return Wallet.findOrCreateUserWalletByCurrency(data.user_id, data.sell_currency, function(err, wallet) {
          if (err || !wallet) {
            return callback("Wallet " + data.sell_currency + " does not exist.");
          }
          return GLOBAL.db.sequelize.transaction(function(transaction) {
            return wallet.holdBalance(holdBalance, transaction, function(err, wallet) {
              if (err || !wallet) {
                console.error(err);
                return transaction.rollback().success(function() {
                  return callback("Not enough " + data.sell_currency + " to open an order.");
                });
              }
              return Order.create(data, {
                transaction: transaction
              }).complete(function(err, newOrder) {
                if (err) {
                  console.error(err);
                  return transaction.rollback().success(function() {
                    return callback(err);
                  });
                }
                return transaction.commit().success(function() {
                  callback(null, newOrder);
                  MarketStats.trackFromNewOrder(newOrder);
                  return TradeHelper.pushUserUpdate({
                    type: "wallet-balance-changed",
                    user_id: wallet.user_id,
                    eventData: JsonRenderer.wallet(wallet)
                  });
                });
              });
            });
          });
        });
      });
    },
    publishOrder: function(orderId, callback) {
      return Order.findById(orderId, function(err, order) {
        if (err) {
          return callback("Could not publish order " + orderId + " - " + err);
        }
        if (!order) {
          return callback("Order " + orderId + " not fund to be published");
        }
        order.published = true;
        order.in_queue = false;
        return order.save().complete(function(err, publishedOrder) {
          if (err) {
            return callback("Could not save published order " + orderId + " - " + err);
          }
          callback(err, publishedOrder);
          return TradeHelper.pushOrderUpdate({
            type: "order-published",
            eventData: JsonRenderer.order(publishedOrder)
          });
        });
      });
    },
    cancelOrder: function(orderId, callback) {
      if (callback == null) {
        callback = function() {};
      }
      return Order.findById(orderId, function(err, order) {
        if (err) {
          return callback("Could not find order to cancel " + orderId + " - " + err);
        }
        if (!order) {
          return callback("Could not find order to cancel " + orderId);
        }
        return Wallet.findUserWalletByCurrency(order.user_id, order.sell_currency, function(err, wallet) {
          return GLOBAL.db.sequelize.transaction(function(transaction) {
            return wallet.holdBalance(-order.left_hold_balance, transaction, function(err, wallet) {
              if (err || !wallet) {
                return transaction.rollback().success(function() {
                  return callback("Could not cancel order " + orderId + " - " + err);
                });
              }
              return order.destroy({
                transaction: transaction
              }).complete(function(err) {
                if (err) {
                  return transaction.rollback().success(function() {
                    return callback(err);
                  });
                }
                return transaction.commit().success(function() {
                  callback();
                  MarketStats.trackFromCancelledOrder(order);
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
              });
            });
          });
        });
      });
    },
    pushOrderUpdate: function(data) {
      return orderSocket.send(data);
    },
    pushUserUpdate: function(data) {
      return usersSocket.send(data);
    },
    matchOrders: function(matchedData, callback) {
      delete matchedData[0].id;
      delete matchedData[1].id;
      return GLOBAL.db.sequelize.transaction(function(transaction) {
        return Order.findByIdWithTransaction(matchedData[0].order_id, transaction, function(err, orderToMatch) {
          if (!orderToMatch || err || orderToMatch.status === "completed") {
            return callback("Wrong order to complete " + matchedData[0].order_id + " - " + err);
          }
          return Order.findByIdWithTransaction(matchedData[1].order_id, transaction, function(err, matchingOrder) {
            if (!matchingOrder || err || orderToMatch.status === "completed") {
              return callback("Wrong order to complete " + matchedData[1].order_id + " - " + err);
            }
            return TradeHelper.updateMatchedOrder(orderToMatch, matchedData[0], transaction, function(err, updatedOrderToMatch, updatedOrderToMatchLog) {
              if (err) {
                console.error("Could not process order " + orderToMatch.id, err);
                return transaction.rollback().success(function() {
                  return callback("Could not process order " + orderToMatch.id + " - " + err);
                });
              }
              return TradeHelper.updateMatchedOrder(matchingOrder, matchedData[1], transaction, function(err, updatedMatchingOrder, updatedMatchingOrderLog) {
                if (err) {
                  console.error("Could not process order " + matchingOrder.id, err);
                  return transaction.rollback().success(function() {
                    return callback("Could not process order " + matchingOrder.id + " - " + err);
                  });
                }
                return transaction.commit().success(function() {
                  return TradeHelper.trackMatchedOrder(updatedOrderToMatchLog, function() {
                    return TradeHelper.trackMatchedOrder(updatedMatchingOrderLog, function() {
                      MarketStats.trackFromMatchedOrder(orderToMatch, matchingOrder);
                      return callback();
                    });
                  });
                });
              });
            });
          });
        });
      });
    },
    updateMatchedOrder: function(orderToMatch, matchData, transaction, callback) {
      return Wallet.findUserWalletByCurrency(orderToMatch.user_id, orderToMatch.buy_currency, function(err, buyWallet) {
        return Wallet.findUserWalletByCurrency(orderToMatch.user_id, orderToMatch.sell_currency, function(err, sellWallet) {
          var changeBalance, holdBalance, matchedAmount, resultAmount, unitPrice;
          matchedAmount = matchData.matched_amount;
          resultAmount = matchData.result_amount;
          unitPrice = matchData.unit_price;
          holdBalance = orderToMatch.action === "buy" ? MarketHelper.multiplyBigints(matchedAmount, orderToMatch.unit_price) : matchedAmount;
          changeBalance = orderToMatch.action === "buy" ? parseInt(math.subtract(MarketHelper.toBignum(holdBalance), MarketHelper.toBignum(MarketHelper.multiplyBigints(matchedAmount, unitPrice)))) : 0;
          return sellWallet.addHoldBalance(-holdBalance, transaction, function(err, sellWallet) {
            if (err || !sellWallet) {
              return callback(err);
            }
            return sellWallet.addBalance(changeBalance, transaction, function(err, sellWallet) {
              if (err || !sellWallet) {
                return callback(err);
              }
              return buyWallet.addBalance(resultAmount, transaction, function(err, buyWallet) {
                if (err || !buyWallet) {
                  return callback(err);
                }
                return orderToMatch.updateFromMatchedData(matchData, transaction, function(err, updatedOrder) {
                  if (err) {
                    console.error("Could not process order ", err);
                  }
                  if (err) {
                    return callback(err);
                  }
                  return OrderLog.logMatch(matchData, transaction, function(err, orderLog) {
                    if (err) {
                      console.error("Could not save order log ", err);
                    }
                    if (err) {
                      return callback(err);
                    }
                    callback(null, updatedOrder, orderLog);
                    TradeHelper.pushUserUpdate({
                      type: "wallet-balance-changed",
                      user_id: sellWallet.user_id,
                      eventData: JsonRenderer.wallet(sellWallet)
                    });
                    return TradeHelper.pushUserUpdate({
                      type: "wallet-balance-changed",
                      user_id: buyWallet.user_id,
                      eventData: JsonRenderer.wallet(buyWallet)
                    });
                  });
                });
              });
            });
          });
        });
      });
    },
    trackMatchedOrder: function(orderLog, callback) {
      var eventType;
      if (callback == null) {
        callback = function() {};
      }
      eventType = orderLog.status === "completed" ? "order-completed" : "order-partially-completed";
      MarketStats.trackFromOrderLog(orderLog, function(err, mkSt) {
        callback(err, mkSt);
        return TradeHelper.pushOrderUpdate({
          type: "market-stats-updated",
          eventData: mkSt.toJSON()
        });
      });
      return orderLog.getOrder().complete(function(err, order) {
        return TradeHelper.pushOrderUpdate({
          type: eventType,
          eventData: JsonRenderer.order(order)
        });
      });
    }
  };

  exports = module.exports = TradeHelper;

}).call(this);
