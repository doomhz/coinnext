(function() {
  var JsonRenderer, MarketHelper, Payment, Wallet, _;

  Payment = GLOBAL.db.Payment;

  Wallet = GLOBAL.db.Wallet;

  MarketHelper = require("../lib/market_helper");

  JsonRenderer = require("../lib/json_renderer");

  _ = require("underscore");

  module.exports = function(app) {
    app.post("/payments", function(req, res) {
      var amount, data;
      amount = parseFloat(req.body.amount);
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      if (!_.isNumber(amount) || _.isNaN(amount) || !_.isFinite(amount)) {
        return JsonRenderer.error("Please submit a valid amount.", res);
      }
      data = {
        user_id: req.user.id,
        wallet_id: req.body.wallet_id,
        amount: MarketHelper.toBigint(amount),
        address: req.body.address
      };
      return Payment.submit(data, function(err, payment) {
        if (err) {
          return JsonRenderer.error(err, res);
        }
        return res.json(JsonRenderer.payment(payment));
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
