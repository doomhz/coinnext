(function() {
  var JsonRenderer, Wallet;

  Wallet = require("../models/wallet");

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    app.post("/wallets", function(req, res) {
      var currency;
      currency = req.body.currency;
      if (req.user) {
        return Wallet.findOrCreateUserWalletByCurrency(req.user.id, currency, function(err, wallet) {
          if (err) {
            console.error(err);
          }
          if (err) {
            return JsonRenderer.error("Could not create wallet.", res);
          }
          return res.json(JsonRenderer.wallet(wallet));
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
