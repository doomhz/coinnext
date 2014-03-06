(function() {
  var ClientSocket, JsonRenderer, Payment, Transaction, User, Wallet, async, restify, usersSocket;

  restify = require("restify");

  async = require("async");

  User = require("../../models/user");

  Wallet = require("../../models/wallet");

  Transaction = require("../../models/transaction");

  Payment = GLOBAL.db.Payment;

  JsonRenderer = require("../../lib/json_renderer");

  ClientSocket = require("../../lib/client_socket");

  usersSocket = new ClientSocket({
    host: GLOBAL.appConfig().app_host,
    path: "users"
  });

  module.exports = function(app) {
    var loadTransaction, processPayment;
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
              if (!err && p.isProcessed()) {
                processedUserIds.push(wallet.user_id);
                return Transaction.update({
                  txid: p.transaction_id
                }, {
                  user_id: p.user_id
                }, function() {
                  callback(null, "" + payment.id + " - processed");
                  return usersSocket.send({
                    type: "payment-processed",
                    user_id: payment.user_id,
                    eventData: JsonRenderer.payment(p)
                  });
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
      return Payment.findByStatus("pending", function(err, payments) {
        return async.mapSeries(payments, processPaymentCallback, function(err, result) {
          if (err) {
            console.log(err);
          }
          return res.send("" + (new Date()) + " - " + result);
        });
      });
    });
    processPayment = function(payment, callback) {
      var account;
      if (callback == null) {
        callback = function() {};
      }
      account = null;
      console.log(payment.address);
      return GLOBAL.wallets[payment.currency].sendToAddress(payment.address, payment.amount, (function(_this) {
        return function(err, response) {
          if (response == null) {
            response = "";
          }
          if (err) {
            console.error("Could not withdraw to " + payment.address + " " + payment.amount + " BTC", err);
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
          return Transaction.addFromWallet(transaction, currency, wallet, function(err, updatedTransaction) {
            if (wallet) {
              usersSocket.send({
                type: "transaction-update",
                user_id: updatedTransaction.user_id,
                eventData: JsonRenderer.transaction(updatedTransaction)
              });
              if (category !== "receive" || updatedTransaction.balance_loaded || !GLOBAL.wallets[currency].isBalanceConfirmed(updatedTransaction.confirmations)) {
                return callback();
              }
              return wallet.addBalance(updatedTransaction.amount, function(err) {
                if (err) {
                  console.error("Could not load user balance " + updatedTransaction.amount, err);
                }
                if (err) {
                  return callback();
                }
                if (err) {
                  console.log("Added balance " + updatedTransaction.amount + " to wallet " + wallet.id + " for tx " + updatedTransaction.id, err);
                }
                return Transaction.update({
                  _id: updatedTransaction.id
                }, {
                  balance_loaded: true
                }, function() {
                  if (err) {
                    console.log("Balance loading to wallet " + wallet.id + " for tx " + updatedTransaction.id + " finished", err);
                  }
                  callback();
                  return usersSocket.send({
                    type: "wallet-balance-loaded",
                    user_id: wallet.user_id,
                    eventData: JsonRenderer.wallet(wallet)
                  });
                });
              });
            } else {
              return Payment.findByTransaction(txId, function(err, payment) {
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
