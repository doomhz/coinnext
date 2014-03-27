(function() {
  var ClientSocket, JsonRenderer, Payment, Transaction, Wallet, async, paymentsProcessedUserIds, restify, usersSocket;

  restify = require("restify");

  async = require("async");

  Wallet = GLOBAL.db.Wallet;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  JsonRenderer = require("../../lib/json_renderer");

  ClientSocket = require("../../lib/client_socket");

  usersSocket = new ClientSocket({
    host: GLOBAL.appConfig().app_host,
    path: "users"
  });

  paymentsProcessedUserIds = [];

  module.exports = function(app) {
    var loadTransaction, pay, processPayment;
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
      paymentsProcessedUserIds = [];
      return Payment.findByStatus("pending", function(err, payments) {
        return async.mapSeries(payments, processPayment, function(err, result) {
          if (err) {
            console.log(err);
          }
          return res.send("" + (new Date()) + " - " + result);
        });
      });
    });
    app.post("/process_payment/:payment_id", function(req, res, next) {
      var paymentId;
      paymentId = req.params.payment_id;
      paymentsProcessedUserIds = [];
      return Payment.findById(paymentId, function(err, payment) {
        return processPayment(payment, function(err, result) {
          return Payment.findById(paymentId, function(err, processedPayment) {
            res.send({
              paymentId: paymentId,
              status: processedPayment.status,
              result: result
            });
            if (processedPayment.isProcessed()) {
              return usersSocket.send({
                type: "payment-processed",
                user_id: payment.user_id,
                eventData: JsonRenderer.payment(processedPayment)
              });
            }
          });
        });
      });
    });
    processPayment = function(payment, callback) {
      return Wallet.findById(payment.wallet_id, function(err, wallet) {
        if (!wallet) {
          return callback(null, "" + payment.id + " - wallet " + payment.wallet_id + " not found");
        }
        if (paymentsProcessedUserIds.indexOf(wallet.user_id) > -1) {
          return callback(null, "" + payment.id + " - user already had a processed payment");
        }
        if (!wallet.canWithdraw(payment.amount)) {
          return callback(null, "" + payment.id + " - not processed - no funds");
        }
        return GLOBAL.db.sequelize.transaction(function(transaction) {
          return wallet.addBalance(-payment.amount, transaction, function(err) {
            if (err) {
              return transaction.rollback().success(function() {
                return callback(null, "" + payment.id + " - not processed - " + err);
              });
            }
            return pay(payment, function(err, p) {
              if (err || !p.isProcessed()) {
                return transaction.rollback().success(function() {
                  return callback(null, "" + payment.id + " - not processed - " + err);
                });
              }
              transaction.commit().success(function() {
                paymentsProcessedUserIds.push(wallet.user_id);
                return Transaction.setUserById(p.transaction_id, p.user_id, function() {
                  callback(null, "" + payment.id + " - processed");
                  return usersSocket.send({
                    type: "payment-processed",
                    user_id: payment.user_id,
                    eventData: JsonRenderer.payment(p)
                  });
                });
              });
              return transaction.done(function(err) {
                if (err) {
                  return callback(null, "" + payment.id + " - not processed - " + err);
                }
              });
            });
          });
        });
      });
    };
    pay = function(payment, callback) {
      if (callback == null) {
        callback = function() {};
      }
      return GLOBAL.wallets[payment.currency].sendToAddress(payment.address, payment.amount, function(err, response) {
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
      });
    };
    return loadTransaction = function(transactionOrId, currency, callback) {
      var txId;
      txId = typeof transactionOrId === "string" ? transactionOrId : transactionOrId.txid;
      if (!txId) {
        return callback();
      }
      return GLOBAL.wallets[currency].getTransaction(txId, function(err, walletTransaction) {
        var account, category;
        if (err) {
          console.error(err);
        }
        if (err) {
          return callback();
        }
        category = walletTransaction.details[0].category;
        account = walletTransaction.details[0].account;
        if (!Transaction.isValidFormat(category)) {
          return callback();
        }
        return Wallet.findByAccount(account, function(err, wallet) {
          return Transaction.addFromWallet(walletTransaction, currency, wallet, function(err, updatedTransaction) {
            if (wallet) {
              usersSocket.send({
                type: "transaction-update",
                user_id: updatedTransaction.user_id,
                eventData: JsonRenderer.transaction(updatedTransaction)
              });
              if (category !== "receive" || updatedTransaction.balance_loaded || !GLOBAL.wallets[currency].isBalanceConfirmed(updatedTransaction.confirmations)) {
                return callback();
              }
              return GLOBAL.db.sequelize.transaction(function(transaction) {
                return wallet.addBalance(updatedTransaction.amount, transaction, function(err) {
                  if (err) {
                    return transaction.rollback().success(function() {
                      return next(new restify.ConflictError("Could not load user balance " + updatedTransaction.amount + " - " + err));
                    });
                  }
                  return Transaction.markAsLoaded(updatedTransaction.id, transaction, function(err) {
                    if (err) {
                      return transaction.rollback().success(function() {
                        return next(new restify.ConflictError("Could not mark the transaction as loaded " + updatedTransaction.id + " - " + err));
                      });
                    }
                    transaction.commit().success(function() {
                      callback();
                      return usersSocket.send({
                        type: "wallet-balance-loaded",
                        user_id: wallet.user_id,
                        eventData: JsonRenderer.wallet(wallet)
                      });
                    });
                    return transaction.done(function(err) {
                      return next(new restify.ConflictError("Could not load transaction " + updatedTransaction.id + " - " + err));
                    });
                  });
                });
              });
            } else {
              return Payment.findByTransaction(txId, function(err, payment) {
                if (!payment) {
                  return callback();
                }
                return Transaction.setUserAndWalletById(txId, payment.user_id, payment.wallet_id, function() {
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
