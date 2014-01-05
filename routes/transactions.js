(function() {
  var JsonRenderer, Payment, Transaction;

  Payment = require("../models/payment");

  Transaction = require("../models/transaction");

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    app.get("/transactions/pending/:wallet_id", function(req, res) {
      var walletId;
      walletId = req.params.wallet_id;
      if (req.user) {
        return Payment.findByUserAndWallet(req.user.id, walletId, "processed", function(err, payments) {
          var payment, txIds, _i, _len;
          txIds = [];
          for (_i = 0, _len = payments.length; _i < _len; _i++) {
            payment = payments[_i];
            txIds.push(payment.transaction_id);
          }
          return Transaction.findPendingByUserAndWallet(req.user.id, walletId, function(err, transactions) {
            if (err) {
              console.error(err);
            }
            return Transaction.findPendingByIds(txIds, function(err, paymentTransactions) {
              if (err) {
                console.error(err);
              }
              if (err) {
                return JsonRenderer.error("Sorry, could not get pending transactions...", res);
              }
              transactions = transactions.concat(paymentTransactions);
              return res.json(JsonRenderer.transactions(transactions));
            });
          });
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
    return app.get("/transactions/:id", function(req, res) {
      var id;
      id = req.params.id;
      if (req.user) {
        return Transaction.findOne({
          _id: id
        }, function(err, transaction) {
          if (err) {
            console.error(err);
          }
          if (err) {
            return JsonRenderer.error("Sorry, could not find transaction...", res);
          }
          return res.json(JsonRenderer.transaction(transaction));
        });
      } else {
        return JsonRenderer.error("Please auth.", res);
      }
    });
  };

}).call(this);
