(function() {
  var JsonRenderer, Wallet;

  Wallet = require("../models/wallet");

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    app.post("/wallets", function(req, res) {
      var currency;
      currency = req.body.currency;
      if (req.user) {
        return Wallet.findUserWalletByCurrency(req.user.id, currency, function(err, wallet) {
          if (!wallet) {
            wallet = new Wallet({
              user_id: req.user.id,
              currency: currency
            });
            return wallet.save(function(err, wl) {
              if (err) {
                return JsonRenderer.error("Sorry, can not create a wallet at this time...", res);
              }
              return res.json(JsonRenderer.wallet(wl));
            });
          } else {
            return JsonRenderer.error("A wallet of this currency already exists.", res);
          }
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
    app.get("/wallets", function(req, res) {
      if (req.user) {
        return Wallet.findUserWallets(req.user.id, function(err, wallets) {
          if (err) {
            console.error(err);
          }
          return res.json(JsonRenderer.wallets(wallets));
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
    return app.put("/wallets/:id", function(req, res) {
      if (req.user) {
        return Wallet.findUserWallet(req.user.id, req.body.id, function(err, wallet) {
          if (err) {
            console.error(err);
          }
          if (wallet) {
            if (req.body.address === "pending") {
              return wallet.generateAddress(req.user.id, function(err, wallet) {
                if (err) {
                  console.error(err);
                  return JsonRenderer.error("Could not generate deposit address.", res);
                }
                return res.json(JsonRenderer.wallet(wallet));
              });
            } else {
              return res.json(JsonRenderer.wallet(wallet));
            }
          } else {
            return JsonRenderer.error("Wrong wallet.", res);
          }
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
  };

}).call(this);
