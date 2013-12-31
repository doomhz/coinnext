(function() {
  var Payment, Transaction, User, Wallet, async, restify;

  restify = require("restify");

  async = require("async");

  User = require("../../models/user");

  Wallet = require("../../models/wallet");

  Transaction = require("../../models/transaction");

  Payment = require("../../models/payment");

  module.exports = function(app) {
    var loadEntireAccountBalance, processPayment;
    app.put("/transaction/:currency/:tx_id", function(req, res, next) {
      var currency, txId;
      txId = req.params.tx_id;
      currency = req.params.currency;
      return GLOBAL.wallets[currency].getTransaction(txId, function(err, transaction) {
        if (err) {
          console.error(err);
        }
        if (transaction && transaction.details[0].category !== "move") {
          return Wallet.findByAccount(transaction.details[0].account, function(err, wallet) {
            return Transaction.addFromWallet(transaction, currency, wallet, function() {
              if (wallet) {
                return loadEntireAccountBalance(wallet, function() {
                  return res.end();
                });
              } else {
                return res.end();
              }
            });
          });
        } else {
          return res.end();
        }
      });
    });
    app.post("/process_pending_payments", function(req, res, next) {
      var processPaymentCallback, processedUserIds;
      processedUserIds = [];
      processPaymentCallback = function(payment, callback) {
        return Wallet.findById(payment.wallet_id, function(err, wallet) {
          if (wallet) {
            if (processedUserIds.indexOf(wallet.user_id) === -1) {
              if (wallet.canWithdraw(payment.amount)) {
                return wallet.addBalance(-payment.amount, function(err) {
                  if (!err) {
                    return processPayment(payment, function(err, p) {
                      if (p.isProcessed()) {
                        processedUserIds.push(wallet.user_id);
                        return callback(null, "" + payment.id + " - processed");
                      } else {
                        wallet.addBalance(payment.amount, function() {});
                        return callback(null, "" + payment.id + " - not processed - " + err);
                      }
                    });
                  } else {
                    return callback(null, "" + payment.id + " - not processed - " + err);
                  }
                });
              } else {
                return callback(null, "" + payment.id + " - not processed - no funds");
              }
            } else {
              return callback(null, "" + payment.id + " - user already had a processed payment");
            }
          } else {
            return callback(null, "" + payment.id + " - wallet " + payment.wallet_id + " not found");
          }
        });
      };
      return Payment.find({
        status: "pending"
      }).exec(function(err, payments) {
        return async.mapSeries(payments, processPaymentCallback, function(err, result) {
          if (err) {
            console.log(err);
          }
          return res.send(result);
        });
      });
    });
    loadEntireAccountBalance = function(wallet, callback) {
      var _this = this;
      if (callback == null) {
        callback = function() {};
      }
      return GLOBAL.wallets[wallet.currency].getBalance(wallet.account, function(err, balance) {
        if (err) {
          console.error("Could not get balance for " + wallet.account, err);
          return callback(err, _this);
        } else {
          if (balance !== 0) {
            return GLOBAL.wallets[wallet.currency].chargeAccount(wallet.account, -balance, function(err, success) {
              if (err) {
                console.error("Could not charge " + wallet.account + " " + balance + " BTC", err);
                return callback(err, _this);
              } else {
                return wallet.addBalance(balance, callback);
              }
            });
          } else {
            return Wallet.findById(wallet.id, callback);
          }
        }
      });
    };
    return processPayment = function(payment, callback) {
      var account,
        _this = this;
      if (callback == null) {
        callback = function() {};
      }
      account = GLOBAL.wallets[payment.currency].account;
      return GLOBAL.wallets[payment.currency].sendToAddress(payment.address, account, payment.amount, function(err, response) {
        if (response == null) {
          response = "";
        }
        if (err) {
          console.error("Could not withdraw to " + payment.address + " from " + account + " " + payment.amount + " BTC", err);
          return payment.errored(err, callback);
        } else {
          return payment.process(response, callback);
        }
      });
    };
  };

}).call(this);
