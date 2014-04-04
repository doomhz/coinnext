(function() {
  var ClientSocket, JsonRenderer, MarketHelper, MarketStats, Order, TradeHelper, Wallet, exports, orderSocket, request, restify;

  restify = require("restify");

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
