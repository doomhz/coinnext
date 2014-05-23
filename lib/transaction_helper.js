(function() {
  var ClientSocket, JsonRenderer, MarketStats, Payment, Transaction, TransactionHelper, Wallet, exports, math, usersSocket;

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

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  TransactionHelper = {
    paymentsProcessedUserIds: [],
    pushToUser: function(data) {
      return usersSocket.send(data);
    },
    createPayment: function(data, callback) {
      return Wallet.findUserWallet(data.user_id, data.wallet_id, function(err, wallet) {
        if (!wallet) {
          return callback("Wrong wallet.");
        }
        if (!wallet.canWithdraw(data.amount, true)) {
          return callback("You don't have enough funds.");
        }
        if (data.address === wallet.address) {
          return callback("You can't withdraw to the same address.");
        }
        data.currency = wallet.currency;
        return GLOBAL.db.sequelize.transaction(function(transaction) {
          return Payment.create(data, {
            transaction: transaction
          }).complete(function(err, pm) {
            var totalWithdrawalAmount;
            if (err) {
              console.error(err);
              return transaction.rollback().success(function() {
                return callback(JsonRenderer.error(err));
              });
            }
            totalWithdrawalAmount = math.add(wallet.withdrawal_fee, pm.amount);
            return wallet.addBalance(-totalWithdrawalAmount, transaction, function(err, wallet) {
              if (err) {
                console.error(err);
                return transaction.rollback().success(function() {
                  return callback(JsonRenderer.error(err));
                });
              }
              transaction.commit().success(function() {
                callback(null, pm);
                return TransactionHelper.pushToUser({
                  type: "wallet-balance-changed",
                  user_id: wallet.user_id,
                  eventData: JsonRenderer.wallet(wallet)
                });
              });
              return transaction.done(function(err) {
                if (err) {
                  return callback(JsonRenderer.error(err));
                }
              });
            });
          });
        });
      });
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
          return TransactionHelper.pay(payment, function(err, p) {
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
        });
      });
    },
    cancelPayment: function(payment, callback) {
      return Wallet.findUserWalletByCurrency(payment.user_id, payment.currency, function(err, wallet) {
        var totalWithdrawalAmount;
        if (err || !wallet) {
          return callback(err);
        }
        totalWithdrawalAmount = math.add(wallet.withdrawal_fee, payment.amount);
        return GLOBAL.db.sequelize.transaction(function(transaction) {
          return wallet.addBalance(totalWithdrawalAmount, transaction, function(err, wallet) {
            if (err) {
              console.error(err);
              return transaction.rollback().success(function() {
                return callback(err);
              });
            }
            return payment.destroy().complete(function(err) {
              if (err) {
                console.error(err);
                return transaction.rollback().success(function() {
                  return callback(err);
                });
              }
              transaction.commit().success(function() {
                callback(null, "" + payment.id + " - removed");
                return usersSocket.send({
                  type: "wallet-balance-changed",
                  user_id: wallet.user_id,
                  eventData: JsonRenderer.wallet(wallet)
                });
              });
              return transaction.done(function(err) {
                if (err) {
                  console.error(err);
                  return callback(err);
                }
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
      return GLOBAL.wallets[payment.currency].sendToAddress(payment.address, payment.getFloat("amount"), function(err, response) {
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
                      if (err) {
                        console.error("Could not load transaction " + updatedTransaction.id + " - " + err);
                      }
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
