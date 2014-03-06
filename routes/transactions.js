(function() {
  var JsonRenderer, Transaction;

  Transaction = GLOBAL.db.Transaction;

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    app.get("/transactions/pending/:wallet_id", function(req, res) {
      var walletId;
      walletId = req.params.wallet_id;
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Transaction.findPendingByUserAndWallet(req.user.id, walletId, function(err, transactions) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return JsonRenderer.error("Sorry, could not get pending transactions...", res);
        }
        return res.json(JsonRenderer.transactions(transactions));
      });
    });
    app.get("/transactions/processed/:wallet_id", function(req, res) {
      var walletId;
      walletId = req.params.wallet_id;
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Transaction.findProcessedByUserAndWallet(req.user.id, walletId, function(err, transactions) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return JsonRenderer.error("Sorry, could not get processed transactions...", res);
        }
        return res.json(JsonRenderer.transactions(transactions));
      });
    });
    return app.get("/transactions/:id", function(req, res) {
      var id;
      id = req.params.id;
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      return Transaction.find(id).complete(function(err, transaction) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return JsonRenderer.error("Sorry, could not find transaction...", res);
        }
        return res.json(JsonRenderer.transaction(transaction));
      });
    });
  };

}).call(this);
