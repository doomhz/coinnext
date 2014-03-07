(function() {
  var JsonRenderer, Payment, Wallet;

  Payment = GLOBAL.db.Payment;

  Wallet = GLOBAL.db.Wallet;

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    app.post("/payments", function(req, res) {
      var address, amount, walletId;
      amount = req.body.amount;
      walletId = req.body.wallet_id;
      address = req.body.address;
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Wallet.findUserWallet(req.user.id, walletId, function(err, wallet) {
        var data;
        if (!wallet) {
          return JsonRenderer.error("Wrong wallet.", res);
        }
        if (!wallet.canWithdraw(amount)) {
          return JsonRenderer.error("You don't have enough funds.", res);
        }
        data = {
          user_id: req.user.id,
          wallet_id: walletId,
          currency: wallet.currency,
          amount: amount,
          address: address
        };
        return Payment.create(data).complete(function(err, pm) {
          if (err) {
            return JsonRenderer.error(err, res);
          }
          return res.json(JsonRenderer.payment(pm));
        });
      });
    });
    return app.get("/payments/pending/:wallet_id", function(req, res) {
      var walletId;
      walletId = req.params.wallet_id;
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Payment.findByUserAndWallet(req.user.id, walletId, "pending", function(err, payments) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return JsonRenderer.error("Sorry, could not get pending payments...", res);
        }
        return res.json(JsonRenderer.payments(payments));
      });
    });
  };

}).call(this);
