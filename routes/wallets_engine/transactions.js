(function() {
  var Payment, Transaction, User, Wallet, async, restify;

  restify = require("restify");

  async = require("async");

  User = require("../../models/user");

  Wallet = require("../../models/wallet");

  Transaction = require("../../models/transaction");

  Payment = require("../../models/payment");

  module.exports = function(app) {
    app.put("/transaction/:currency/:tx_id", function(req, res, next) {
      var currency, txId;
      txId = req.params.tx_id;
      currency = req.params.currency;
      GLOBAL.wallets[currency].getTransaction(txId, function(err, transaction) {
        if (err) {
          console.error(err);
        }
        if (transaction && transaction.details[0].category !== "move") {
          if (transaction.details[0].account) {
            return User.findById(transaction.details[0].account, function(err, user) {
              if (user) {
                return Wallet.findUserWalletByCurrency(user.id, currency, function(err, wallet) {
                  Transaction.addFromWallet(transaction, currency, user, wallet);
                  if (wallet) {
                    return wallet.syncBalance();
                  }
                });
              } else {
                return Transaction.addFromWallet(transaction, currency, user);
              }
            });
          } else {
            return Transaction.addFromWallet(transaction, currency);
          }
        }
      });
      return res.end();
    });
    return app.post("/process_pending_payments", function(req, res, next) {
      var processPayment;
      processPayment = function(payment, callback) {
        return Wallet.findById(payment.wallet_id, function(err, wallet) {
          if (wallet.canWithdraw(payment.amount)) {
            return wallet.addBalance(-payment.amount, function(err) {
              if (!err) {
                return payment.process(function(err) {
                  if (!err) {
                    return callback(null, "" + payment.id + " - processed");
                  } else {
                    return wallet.addBalance(payment.amount, function() {
                      return callback(null, "" + payment.id + " - not processed - " + err);
                    });
                  }
                });
              } else {
                return callback(null, "" + payment.id + " - not processed - " + err);
              }
            });
          } else {
            return callback(null, "" + payment.id + " - not processed - no funds");
          }
        });
      };
      return Payment.find({
        status: "pending"
      }).exec(function(err, payments) {
        return async.mapSeries(payments, processPayment, function(err, result) {
          if (err) {
            console.log(err);
          }
          return console.log(result);
        });
      });
    });
  };

}).call(this);
