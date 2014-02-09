(function() {
  var JsonRenderer, MarketStats, Order, Wallet;

  Order = require("../models/order");

  Wallet = require("../models/wallet");

  MarketStats = require("../models/market_stats");

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    var calculateHoldBalance, notValidOrderData;
    app.post("/orders", function(req, res) {
      var data, validationError;
      if (!req.user) {
        return JsonRenderer.error("You need to be logged in to place an order.", res);
      }
      if (!req.user.canTrade()) {
        return JsonRenderer.error("Sorry, but you can not trade. Did you verify your account?", res);
      }
      data = req.body;
      data.user_id = req.user.id;
      if (validationError = notValidOrderData(data)) {
        return JsonRenderer.error(validationError, res);
      }
      return calculateHoldBalance(data, function(err, holdBalance) {
        return Wallet.findOrCreateUserWalletByCurrency(req.user.id, data.buy_currency, function(err, buyWallet) {
          if (err || !buyWallet) {
            return JsonRenderer.error("Wallet " + data.buy_currency + " does not exist.", res);
          }
          return Wallet.findOrCreateUserWalletByCurrency(req.user.id, data.sell_currency, function(err, wallet) {
            if (err || !wallet) {
              return JsonRenderer.error("Wallet " + data.sell_currency + " does not exist.", res);
            }
            return wallet.holdBalance(holdBalance, function(err, wallet) {
              if (err || !wallet) {
                return JsonRenderer.error("Not enough " + data.sell_currency + " to open an order.", res);
              }
              data.hold_amount = holdBalance;
              return Order.create(data, function(err, newOrder) {
                if (err) {
                  return JsonRenderer.error("Sorry, could not open an order...", res);
                }
                return newOrder.publish(function(err, order) {
                  if (err) {
                    console.log("Could not publish newlly created order - " + err);
                  }
                  if (err) {
                    return res.json(JsonRenderer.order(newOrder));
                  }
                  return res.json(JsonRenderer.order(order));
                });
              });
            });
          });
        });
      });
    });
    app.get("/orders", function(req, res) {
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
      return Order.findOne({
        user_id: req.user.id,
        _id: req.params.id
      }, function(err, order) {
        if (err || !order) {
          return JsonRenderer.error("Sorry, could not delete orders...", res);
        }
        return order.cancel(function(err) {
          if (err) {
            console.log("Could not cancel order - " + err);
          }
          if (err) {
            return res.json(JsonRenderer.order(order));
          }
          return res.json({});
        });
      });
    });
    calculateHoldBalance = function(orderData, callback) {
      var holdBalance;
      if (callback == null) {
        callback = function() {};
      }
      if (orderData.action === "sell") {
        holdBalance = orderData.amount;
        return callback(null, holdBalance);
      }
      if (orderData.action === "buy") {
        return MarketStats.getStats(function(err, stats) {
          var marketType, unitPrice;
          marketType = "" + orderData.buy_currency + "_" + orderData.sell_currency;
          if (orderData.type === "limit") {
            unitPrice = orderData.unit_price;
          }
          if (orderData.type === "market") {
            unitPrice = stats[marketType].last_price;
          }
          holdBalance = orderData.amount * unitPrice;
          return callback(null, holdBalance);
        });
      }
    };
    return notValidOrderData = function(orderData) {
      if (!Order.isValidTradeAmount(orderData.amount)) {
        return "Please submit a valid amount bigger than 0.";
      }
      if (orderData.type === "limit" && !Order.isValidTradeAmount(orderData.unit_price)) {
        return "Please submit a valid unit price amount.";
      }
      if (["buy", "sell"].indexOf(orderData.action) === -1) {
        return "Please submit a valid action.";
      }
      if (Wallet.getCurrencies().indexOf(orderData.buy_currency) === -1) {
        return "Please submit a valid buy currency.";
      }
      if (Wallet.getCurrencies().indexOf(orderData.sell_currency) === -1) {
        return "Please submit a valid sell currency.";
      }
      if (orderData.buy_currency === orderData.sell_currency) {
        return "Please submit different currencies.";
      }
      if (!MarketStats.isValidMarket(orderData.action, orderData.buy_currency, orderData.sell_currency)) {
        return "Invalid market.";
      }
      return false;
    };
  };

}).call(this);
