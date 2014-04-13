(function() {
  var ClientSocket, JsonRenderer, MarketHelper, MarketStats, Order, TradeHelper, Wallet, exports, math, orderSocket, request, usersSocket;

  request = require("request");

  Order = GLOBAL.db.Order;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  JsonRenderer = require("./json_renderer");

  MarketHelper = require("./market_helper");

  ClientSocket = require("./client_socket");

  orderSocket = new ClientSocket({
    host: GLOBAL.appConfig().app_host,
    path: "orders"
  });

  usersSocket = new ClientSocket({
    host: GLOBAL.appConfig().app_host,
    path: "users"
  });

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  TradeHelper = {
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
        amount: order.getDataValue("amount"),
        unit_price: order.getDataValue("unit_price")
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
          if (err || response.statusCode !== 200) {
            err = "" + response.statusCode + " - Could not send order data to " + uri + " - " + (JSON.stringify(options.json)) + " - " + (JSON.stringify(err)) + " - " + (JSON.stringify(body));
            console.log(err);
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
          var changeBalance, fee, holdBalance, matchedAmount, resultAmount, status, unitPrice;
          matchedAmount = MarketHelper.convertFromBigint(matchData.matched_amount);
          resultAmount = MarketHelper.convertFromBigint(matchData.result_amount);
          unitPrice = MarketHelper.convertFromBigint(matchData.unit_price);
          fee = MarketHelper.convertFromBigint(matchData.fee);
          status = matchData.status;
          holdBalance = orderToMatch.action === "buy" ? math.multiply(matchedAmount, orderToMatch.unit_price) : matchedAmount;
          changeBalance = orderToMatch.action === "buy" ? math.add(holdBalance, -math.multiply(matchedAmount, unitPrice)) : 0;
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
                orderToMatch.status = status;
                orderToMatch.sold_amount = math.add(orderToMatch.sold_amount, matchedAmount);
                orderToMatch.result_amount = math.add(orderToMatch.result_amount, resultAmount);
                orderToMatch.fee = math.add(orderToMatch.fee, fee);
                if (status === "completed") {
                  orderToMatch.close_time = Date.now();
                }
                return orderToMatch.save({
                  transaction: transaction
                }).complete(function(err, updatedOrder) {
                  if (err) {
                    console.error("Could not process order ", err);
                  }
                  if (err) {
                    return callback(err);
                  }
                  callback(null, updatedOrder);
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
    },
    trackMatchedOrder: function(order, callback) {
      if (callback == null) {
        callback = function() {};
      }
      if (order.status === "completed") {
        MarketStats.trackFromOrder(order, function(err, mkSt) {
          callback(err, mkSt);
          return TradeHelper.send({
            type: "market-stats-updated",
            eventData: mkSt.toJSON()
          });
        });
        TradeHelper.pushOrderUpdate({
          type: "order-completed",
          eventData: JsonRenderer.order(order)
        });
      }
      if (order.status === "partiallyCompleted") {
        TradeHelper.pushOrderUpdate({
          type: "order-partially-completed",
          eventData: JsonRenderer.order(order)
        });
        return callback();
      } else {
        return callback();
      }
    }
  };

  exports = module.exports = TradeHelper;

}).call(this);
