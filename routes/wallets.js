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
            return wallet.save(function(err, wallet) {
              if (err) {
                return JsonRenderer.error("Sorry, can not create a wallet at this time...", res);
              }
              return wallet.generateAddress(function(err, wl) {
                if (err) {
                  console.error(err);
                }
                return res.json(JsonRenderer.wallet(wl || wallet));
              });
            });
          } else {
            return JsonRenderer.error("A wallet of this currency already exists.", res);
          }
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
    return app.get("/wallets", function(req, res) {
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
  };

}).call(this);
