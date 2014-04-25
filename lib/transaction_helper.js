(function() {
  var ClientSocket, JsonRenderer, MarketStats, Payment, Transaction, TransactionHelper, Wallet, exports, usersSocket;

  Wallet = GLOBAL.db.Wallet;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  MarketStats = GLOBAL.db.MarketStats;

  JsonRenderer = require("./json_renderer");

  ClientSocket = require("./client_socket");

  usersSocket = new ClientSocket({
    namespace: "users",
    redis: GLOBAL.appConfig().redis
  });

  TransactionHelper = {
    paymentsProcessedUserIds: [],
    pushToUser: function(data) {
      return usersSocket.send(data);
    },
    processPayment: function(payment, callback) {
      return MarketStats.findEnabledMarket(payment.currency, "BTC", function(err, market) {
        if (!market) {
          return callback(null, "" + (new Date()) + " - Will not process payment " + payment.id + ", the market for " + payment.currency + " is disabled.");
        }
        return Wallet.findById(payment.wallet_id, function(err, wallet) {
          if (!wallet) {
            return callback(null, "" + payment.id + " - wallet " + payment.wallet_id + " not found");
          }
          if (TransactionHelper.paymentsProcessedUserIds.indexOf(wallet.user_id) > -1) {
            return callback(null, "" + payment.id + " - user already had a processed payment");
          }
          if (!wallet.canWithdraw(payment.amount, true)) {
            return callback(null, "" + payment.id + " - not processed - no funds");
          }
          return GLOBAL.db.sequelize.transaction(function(transaction) {
            return wallet.addBalance(-payment.amount, transaction, function(err) {
              if (err) {
                return transaction.rollback().success(function() {
                  return callback(null, "" + payment.id + " - not processed - " + err);
                });
              }
              return wallet.addBalance(-wallet.withdrawal_fee, transaction, function(err) {
                if (err) {
                  return transaction.rollback().success(function() {
                    return callback(null, "" + payment.id + " - not processed - " + err);
                  });
                }
                return TransactionHelper.pay(payment, function(err, p) {
                  if (err || !p.isProcessed()) {
                    return transaction.rollback().success(function() {
                      return callback(null, "" + payment.id + " - not processed - " + err);
                    });
                  }
                  transaction.commit().success(function() {
                    TransactionHelper.paymentsProcessedUserIds.push(wallet.user_id);
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
        });
      });
    },
    pay: function(payment, callback) {
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
    },
    loadTransaction: function(transactionData, currency, callback) {
      var txId;
      txId = transactionData.txid;
      if (!txId) {
        return callback();
      }
      return MarketStats.findEnabledMarket(currency, "BTC", function(err, market) {
        var address, category;
        if (!market) {
          console.error("" + (new Date()) + " - Will not load the transaction " + txId + ", the market for " + currency + " is disabled.");
          return callback();
        }
        category = transactionData.category;
        address = transactionData.address;
        if (!Transaction.isValidFormat(category)) {
          return callback();
        }
        return Wallet.findByAddress(address, function(err, wallet) {
          return Transaction.addFromWallet(transactionData, currency, wallet, function(err, updatedTransaction) {
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
                      console.error("Could not load user balance " + updatedTransaction.amount + " - " + err);
                      return callback();
                    });
                  }
                  return Transaction.markAsLoaded(updatedTransaction.id, transaction, function(err) {
                    if (err) {
                      return transaction.rollback().success(function() {
                        console.error("Could not mark the transaction as loaded " + updatedTransaction.id + " - " + err);
                        return callback();
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
                      console.error("Could not load transaction " + updatedTransaction.id + " - " + err);
                      return callback();
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
    }
  };

  exports = module.exports = TransactionHelper;

}).call(this);
