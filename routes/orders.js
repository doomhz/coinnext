(function() {
  var JsonRenderer, Order, Wallet;

  Order = require("../models/order");

  Wallet = require("../models/wallet");

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    app.post("/orders", function(req, res) {
      var data;
      if (req.user) {
        data = req.body;
        data.user_id = req.user.id;
        return Wallet.findUserWalletByCurrency(req.user.id, data.buy_currency, function(err, buyWallet) {
          if (err || !buyWallet) {
            return JsonRenderer.error("Wallet " + data.buy_currency + " does not exist.", res);
          }
          return Wallet.findUserWalletByCurrency(req.user.id, data.sell_currency, function(err, wallet) {
            if (err || !wallet) {
              return JsonRenderer.error("Wallet " + data.sell_currency + " does not exist.", res);
            }
            return wallet.holdBalance(parseFloat(data.amount), function(err, wallet) {
              if (err || !wallet) {
                return JsonRenderer.error("Not enough " + data.sell_currency + " to open an order.", res);
              }
              return Order.create(data, function(err, order) {
                if (err) {
                  return JsonRenderer.error("Sorry, could not open an order...", res);
                }
                return res.json(JsonRenderer.order(order));
              });
            });
          });
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
    app.get("/orders/open/:currency1/:currency2", function(req, res) {
      var currency1, currency2;
      currency1 = req.params.currency1;
      currency2 = req.params.currency2;
      if (req.user) {
        return Order.findOpenByUserAndCurrencies(req.user.id, [currency1, currency2], function(err, orders) {
          if (err) {
            return JsonRenderer.error("Sorry, could not get open orders...", res);
          }
          return res.json(JsonRenderer.orders(orders));
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
    app.get("/orders/:status/:action/:currency1/:currency2", function(req, res) {
      var action, currency1, currency2, status;
      status = req.params.status;
      currency1 = req.params.currency1;
      currency2 = req.params.currency2;
      action = req.params.action;
      if (req.user) {
        return Order.findByStatusActionAndCurrencies(status, action, currency1, currency2, function(err, orders) {
          if (err) {
            return JsonRenderer.error("Sorry, could not get open orders...", res);
          }
          return res.json(JsonRenderer.orders(orders));
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
    return app.del("/orders/:id", function(req, res) {
      if (req.user) {
        return Order.findOne({
          user_id: req.user.id,
          _id: req.params.id
        }, function(err, order) {
          if (err || !order) {
            return JsonRenderer.error("Sorry, could not delete orders...", res);
          }
          return Wallet.findUserWalletByCurrency(req.user.id, order.sell_currency, function(err, wallet) {
            return wallet.holdBalance(-order.amount, function(err, wallet) {
              return order.remove(function() {
                return res.json(JsonRenderer.orders(order));
              });
            });
          });
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
  };

}).call(this);
