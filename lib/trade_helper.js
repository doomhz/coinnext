(function() {
  var ClientSocket, JsonRenderer, MarketHelper, MarketStats, Order, OrderLog, TradeHelper, Wallet, exports, math, orderSocket, request, usersSocket;

  request = require("request");

  Order = GLOBAL.db.Order;

  OrderLog = GLOBAL.db.OrderLog;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

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

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  TradeHelper = {
    createOrder: function(data, callback) {
      var holdBalance;
      if (callback == null) {
        callback = function() {};
      }
      if (data.type === "limit" && data.action === "buy") {
        holdBalance = math.multiply(data.amount, MarketHelper.fromBigint(data.unit_price));
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
                transaction.commit().success(function() {
                  callback(null, newOrder);
                  return TradeHelper.pushUserUpdate({
                    type: "wallet-balance-changed",
                    user_id: wallet.user_id,
                    eventData: JsonRenderer.wallet(wallet)
                  });
                });
                return transaction.done(function(err) {
                  if (err) {
                    return callback("Could not open an order. Please try again later.");
                  }
                });
              });
            });
          });
        });
      });
    },
    submitOrder: function(order, callback) {
      var options, orderData, uri;
      if (callback == null) {
        callback = function() {};
      }
      orderData = {
        order_id: order.id,
        type: order.type,
        action: order.action,
        buy_currency: order.buy_currency,
        sell_currency: order.sell_currency,
        amount: order.amount,
        unit_price: order.unit_price
      };
      uri = "" + (GLOBAL.appConfig().engine_api_host) + "/order/" + order.id;
      options = {
        uri: uri,
        method: "POST",
        json: orderData
      };
      return this.sendEngineData(uri, options, callback);
    },
    cancelOrder: function(order, callback) {
      var options, uri;
      if (callback == null) {
        callback = function() {};
      }
      if (!order.published) {
        return callback();
      }
      uri = "" + (GLOBAL.appConfig().engine_api_host) + "/order/" + order.id;
      options = {
        uri: uri,
        method: "DELETE"
      };
      return this.sendEngineData(uri, options, callback);
    },
    sendEngineData: function(uri, options, callback) {
      var e;
      try {
        return request(options, function(err, response, body) {
          if (response == null) {
            response = {};
          }
          if (err || response.statusCode !== 200) {
            err = "" + response.statusCode + " - Could not send order data to " + uri + " - " + (JSON.stringify(options.json)) + " - " + (JSON.stringify(err)) + " - " + (JSON.stringify(body));
            console.error(err);
            return callback(err);
          }
          return callback();
        });
      } catch (_error) {
        e = _error;
        console.error(e);
        return callback("Bad response " + e);
      }
    },
    pushOrderUpdate: function(data) {
      return orderSocket.send(data);
    },
    pushUserUpdate: function(data) {
      return usersSocket.send(data);
    },
    updateMatchedOrder: function(orderToMatch, matchData, transaction, callback) {
      return Wallet.findUserWalletByCurrency(orderToMatch.user_id, orderToMatch.buy_currency, function(err, buyWallet) {
        return Wallet.findUserWalletByCurrency(orderToMatch.user_id, orderToMatch.sell_currency, function(err, sellWallet) {
          var changeBalance, holdBalance, matchedAmount, resultAmount, unitPrice;
          matchedAmount = matchData.matched_amount;
          resultAmount = matchData.result_amount;
          unitPrice = matchData.unit_price;
          holdBalance = orderToMatch.action === "buy" ? math.multiply(matchedAmount, MarketHelper.fromBigint(orderToMatch.unit_price)) : matchedAmount;
          changeBalance = orderToMatch.action === "buy" ? math.add(holdBalance, -math.multiply(matchedAmount, MarketHelper.fromBigint(unitPrice))) : 0;
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
        return TradeHelper.send({
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
