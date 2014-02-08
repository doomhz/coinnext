(function() {
  var Payment, Transaction, User, Wallet, async, restify;

  restify = require("restify");

  async = require("async");

  User = require("../../models/user");

  Wallet = require("../../models/wallet");

  Transaction = require("../../models/transaction");

  Payment = require("../../models/payment");

  module.exports = function(app) {
    var loadEntireAccountBalance, loadTransaction, processPayment;
    app.put("/transaction/:currency/:tx_id", function(req, res, next) {
      var currency, txId;
      txId = req.params.tx_id;
      currency = req.params.currency;
      console.log(txId);
      console.log(currency);
      return loadTransaction(txId, currency, function() {
        return res.end();
      });
    });
    app.post("/load_latest_transactions/:currency", function(req, res, next) {
      var currency;
      currency = req.params.currency;
      return GLOBAL.wallets[currency].getTransactions("*", 100, 0, function(err, transactions) {
        var loadTransactionCallback;
        if (err) {
          console.error(err);
        }
        loadTransactionCallback = function(transaction, callback) {
          return loadTransaction(transaction, currency, callback);
        };
        if (!transactions) {
          return res.send("" + (new Date()) + " - Nothing to process");
        }
        return async.mapSeries(transactions, loadTransactionCallback, function(err, result) {
          if (err) {
            console.error(err);
          }
          return res.send("" + (new Date()) + " - Processed " + result.length + " transactions");
        });
      });
    });
    app.post("/process_pending_payments", function(req, res, next) {
      var processPaymentCallback, processedUserIds;
      processedUserIds = [];
      processPaymentCallback = function(payment, callback) {
        return Wallet.findById(payment.wallet_id, function(err, wallet) {
          if (!wallet) {
            return callback(null, "" + payment.id + " - wallet " + payment.wallet_id + " not found");
          }
          if (processedUserIds.indexOf(wallet.user_id) > -1) {
            return callback(null, "" + payment.id + " - user already had a processed payment");
          }
          if (!wallet.canWithdraw(payment.amount)) {
            return callback(null, "" + payment.id + " - not processed - no funds");
          }
          return wallet.addBalance(-payment.amount, function(err) {
            if (err) {
              return callback(null, "" + payment.id + " - not processed - " + err);
            }
            return processPayment(payment, function(err, p) {
              if (p.isProcessed()) {
                processedUserIds.push(wallet.user_id);
                return Transaction.update({
                  txid: p.transaction_id
                }, {
                  user_id: p.user_id
                }, function() {
                  return callback(null, "" + payment.id + " - processed");
                });
              } else {
                return wallet.addBalance(payment.amount, function() {
                  return callback(null, "" + payment.id + " - not processed - " + err);
                });
              }
            });
          });
        });
      };
      return Payment.find({
        status: "pending"
      }).sort({
        created: "asc"
      }).exec(function(err, payments) {
        return async.mapSeries(payments, processPaymentCallback, function(err, result) {
          if (err) {
            console.log(err);
          }
          return res.send("" + (new Date()) + " - " + result);
        });
      });
    });
    loadEntireAccountBalance = function(wallet, callback) {
      if (callback == null) {
        callback = function() {};
      }
      return GLOBAL.wallets[wallet.currency].getBalance(wallet.account, (function(_this) {
        return function(err, balance) {
          if (err) {
            console.error("Could not get balance for " + wallet.account, err);
          }
          if (err) {
            return callback(err, _this);
          }
          if (balance <= 0) {
            return Wallet.findById(wallet.id, callback);
          }
          return GLOBAL.wallets[wallet.currency].chargeAccount(wallet.account, -balance, function(err, success) {
            if (err) {
              console.error("Could not charge " + wallet.account + " " + balance + " BTC", err);
            }
            if (err) {
              return callback(err, _this);
            }
            return wallet.addBalance(balance, callback);
          });
        };
      })(this));
    };
    processPayment = function(payment, callback) {
      var account;
      if (callback == null) {
        callback = function() {};
      }
      account = null;
      console.log(payment.address);
      return GLOBAL.wallets[payment.currency].sendToAddress(payment.address, account, payment.amount, (function(_this) {
        return function(err, response) {
          if (response == null) {
            response = "";
          }
          if (err) {
            console.error("Could not withdraw to " + payment.address + " from " + account + " " + payment.amount + " BTC", err);
          }
          if (err) {
            return payment.errored(err, callback);
          }
          return payment.process(response, callback);
        };
      })(this));
    };
    return loadTransaction = function(transactionOrId, currency, callback) {
      var txId;
      txId = typeof transactionOrId === "string" ? transactionOrId : transactionOrId.txid;
      if (!txId) {
        return callback();
      }
      return GLOBAL.wallets[currency].getTransaction(txId, function(err, transaction) {
        var account, category;
        if (err) {
          console.error(err);
        }
        if (err) {
          return callback();
        }
        category = transaction.details[0].category;
        account = transaction.details[0].account;
        if (!Transaction.isValidFormat(category)) {
          return callback();
        }
        return Wallet.findByAccount(account, function(err, wallet) {
          return Transaction.addFromWallet(transaction, currency, wallet, function() {
            if (wallet) {
              if (category !== "receive") {
                return callback();
              }
              return loadEntireAccountBalance(wallet, function() {
                return callback();
              });
            } else {
              return Payment.findOne({
                transaction_id: txId
              }, function(err, payment) {
                if (!payment) {
                  return callback();
                }
                return Transaction.update({
                  txid: txId
                }, {
                  user_id: payment.user_id,
                  wallet_id: payment.wallet_id
                }, function() {
                  return callback();
                });
              });
            }
          });
        });
      });
    };
  };

}).call(this);
