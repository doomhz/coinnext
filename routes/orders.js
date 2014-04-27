(function() {
  var ClientSocket, JsonRenderer, MarketHelper, MarketStats, Order, Wallet, math, usersSocket, _;

  Order = GLOBAL.db.Order;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  MarketHelper = require("../lib/market_helper");

  JsonRenderer = require("../lib/json_renderer");

  ClientSocket = require("../lib/client_socket");

  _ = require("underscore");

  usersSocket = new ClientSocket({
    namespace: "users",
    redis: GLOBAL.appConfig().redis
  });

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  module.exports = function(app) {
    var notValidOrderData;
    app.post("/orders", function(req, res) {
      var data, orderCurrency, validationError;
      if (!req.user) {
        return JsonRenderer.error("You need to be logged in to place an order.", res);
      }
      if (!req.user.canTrade()) {
        return JsonRenderer.error("Sorry, but you can not trade. Did you verify your account?", res);
      }
      data = req.body;
      data.user_id = req.user.id;
      data.status = "open";
      data.amount = parseFloat(data.amount);
      if (_.isNumber(data.amount) && !_.isNaN(data.amount) && _.isFinite(data.amount)) {
        data.amount = MarketHelper.toBigint(data.amount);
      }
      data.unit_price = parseFloat(data.unit_price);
      if (_.isNumber(data.unit_price) && !_.isNaN(data.unit_price) && _.isFinite(data.unit_price)) {
        data.unit_price = MarketHelper.toBigint(data.unit_price);
      }
      if (validationError = notValidOrderData(data)) {
        return JsonRenderer.error(validationError, res);
      }
      orderCurrency = data["" + data.action + "_currency"];
      return MarketStats.findEnabledMarket(orderCurrency, "BTC", function(err, market) {
        var holdBalance;
        if (!market) {
          return JsonRenderer.error("Can't submit the order, the " + orderCurrency + " market is closed at the moment.", res);
        }
        if (data.type === "limit" && data.action === "buy") {
          holdBalance = math.multiply(data.amount, MarketHelper.fromBigint(data.unit_price));
        }
        if (data.type === "limit" && data.action === "sell") {
          holdBalance = data.amount;
        }
        return Wallet.findOrCreateUserWalletByCurrency(req.user.id, data.buy_currency, function(err, buyWallet) {
          if (err || !buyWallet) {
            return JsonRenderer.error("Wallet " + data.buy_currency + " does not exist.", res);
          }
          return Wallet.findOrCreateUserWalletByCurrency(req.user.id, data.sell_currency, function(err, wallet) {
            if (err || !wallet) {
              return JsonRenderer.error("Wallet " + data.sell_currency + " does not exist.", res);
            }
            return GLOBAL.db.sequelize.transaction(function(transaction) {
              return wallet.holdBalance(holdBalance, transaction, function(err, wallet) {
                if (err || !wallet) {
                  console.error(err);
                  return transaction.rollback().success(function() {
                    return JsonRenderer.error("Not enough " + data.sell_currency + " to open an order.", res);
                  });
                }
                return Order.create(data, {
                  transaction: transaction
                }).complete(function(err, newOrder) {
                  if (err) {
                    console.error(err);
                    return transaction.rollback().success(function() {
                      return JsonRenderer.error("Sorry, could not open an order...", res);
                    });
                  }
                  transaction.commit().success(function() {
                    newOrder.publish(function(err, order) {
                      if (err) {
                        console.error("Could not publish newlly created order - " + err);
                      }
                      if (err) {
                        return res.json(JsonRenderer.order(newOrder));
                      }
                      return res.json(JsonRenderer.order(order));
                    });
                    return usersSocket.send({
                      type: "wallet-balance-changed",
                      user_id: wallet.user_id,
                      eventData: JsonRenderer.wallet(wallet)
                    });
                  });
                  return transaction.done(function(err) {
                    if (err) {
                      return JsonRenderer.error("Could not open an order. Please try again later.", res);
                    }
                  });
                });
              });
            });
          });
        });
      });
    });
    app.get("/orders", function(req, res) {
      if (req.query.user_id != null) {
        req.query.user_id = req.user.id;
      }
      return Order.findByOptions(req.query, function(err, orders) {
        if (err) {
          return JsonRenderer.error("Sorry, could not get open orders...", res);
        }
        return res.json(JsonRenderer.orders(orders));
      });
    });
    app.del("/orders/:id", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error("You need to be logged in to delete an order.", res);
      }
      return Order.findByUserAndId(req.params.id, req.user.id, function(err, order) {
        if (err || !order) {
          return JsonRenderer.error("Sorry, could not delete orders...", res);
        }
        return order.cancel(function(err) {
          if (err) {
            console.error("Could not cancel order - " + err);
          }
          if (err) {
            return res.json(JsonRenderer.order(order));
          }
          return res.json({});
        });
      });
    });
    return notValidOrderData = function(orderData) {
      if (orderData.type === "market") {
        return "Market orders are disabled at the moment.";
      }
      if (!Order.isValidTradeAmount(orderData.amount)) {
        return "Please submit a valid amount bigger than 0.0000001.";
      }
      if (orderData.type === "limit" && !Order.isValidTradeAmount(orderData.unit_price)) {
        return "Please submit a valid unit price amount.";
      }
      if (!MarketHelper.getOrderAction(orderData.action)) {
        return "Please submit a valid action.";
      }
      if (!MarketHelper.isValidCurrency(orderData.buy_currency)) {
        return "Please submit a valid buy currency.";
      }
      if (!MarketHelper.isValidCurrency(orderData.sell_currency)) {
        return "Please submit a valid sell currency.";
      }
      if (orderData.buy_currency === orderData.sell_currency) {
        return "Please submit different currencies.";
      }
      if (!MarketHelper.isValidMarket(orderData.action, orderData.buy_currency, orderData.sell_currency)) {
        return "Invalid market.";
      }
      if (!Order.isValidSpendAmount(orderData.amount, orderData.action, orderData.unit_price)) {
        return "Trade amount is too low, please submit a bigger amount.";
      }
      if (!Order.isValidFee(orderData.amount, orderData.action, orderData.unit_price)) {
        return "Trade amount is too low, please submit a bigger amount.";
      }
      return false;
    };
  };

}).call(this);
