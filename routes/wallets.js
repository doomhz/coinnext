(function() {
  var JsonRenderer, MarketHelper, Wallet;

  Wallet = GLOBAL.db.Wallet;

  MarketHelper = require("../lib/market_helper");

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    app.post("/wallets", function(req, res) {
      var currency;
      currency = req.body.currency;
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      if (!MarketHelper.isValidCurrency(currency)) {
        return JsonRenderer.error("Invalid currency.", res);
      }
      return Wallet.findOrCreateUserWalletByCurrency(req.user.id, currency, function(err, wallet) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return JsonRenderer.error("Could not create wallet.", res);
        }
        return res.json(JsonRenderer.wallet(wallet));
      });
    });
    app.put("/wallets/:id", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Wallet.findUserWallet(req.user.id, req.params.id, function(err, wallet) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return JsonRenderer.error("Wrong wallet.", res);
        }
        if (wallet.address) {
          return res.json(JsonRenderer.wallet(wallet));
        }
        return wallet.generateAddress(function(err, wl) {
          if (err) {
            console.error(err);
          }
          if (err) {
            return JsonRenderer.error("Could not generate address.", res);
          }
          return res.json(JsonRenderer.wallet(wl));
        });
      });
    });
    app.get("/wallets/:id", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Wallet.findUserWallet(req.user.id, req.params.id, function(err, wallet) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return JsonRenderer.error("Wrong wallet.", res);
        }
        return res.json(JsonRenderer.wallet(wallet));
      });
    });
    return app.get("/wallets", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Wallet.findUserWallets(req.user.id, function(err, wallets) {
        if (err) {
          console.error(err);
        }
        return res.json(JsonRenderer.wallets(wallets));
      });
    });
  };

}).call(this);
