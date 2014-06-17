(function() {
  var ClientSocket, FraudHelper, JsonRenderer, MarketHelper, MarketStats, Payment, Transaction, TransactionHelper, Wallet, exports, math, usersSocket;

  Wallet = GLOBAL.db.Wallet;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  MarketStats = GLOBAL.db.MarketStats;

  MarketHelper = require("./market_helper");

  FraudHelper = require("./fraud_helper");

  JsonRenderer = require("./json_renderer");

  ClientSocket = require("./client_socket");

  math = require("./math");

  usersSocket = new ClientSocket({
    namespace: "users",
    redis: GLOBAL.appConfig().redis
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
        data.fee = wallet.withdrawal_fee;
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
            totalWithdrawalAmount = parseInt(math.add(MarketHelper.toBignum(wallet.withdrawal_fee), MarketHelper.toBignum(pm.amount)));
            return wallet.addBalance(-totalWithdrawalAmount, transaction, function(err, wallet) {
              if (err) {
                console.error(err);
                return transaction.rollback().success(function() {
                  return callback(JsonRenderer.error(err));
                });
              }
              return transaction.commit().success(function() {
                callback(null, pm);
                return TransactionHelper.pushToUser({
                  type: "wallet-balance-changed",
                  user_id: wallet.user_id,
                  eventData: JsonRenderer.wallet(wallet)
                });
              });
            });
          });
        });
      });
    },
    processPaymentWithFraud: function(payment, callback) {
      return FraudHelper.checkUserBalances(payment.user_id, function(err, result) {
        if (!result.valid_final_balance || !result.valid_hold_balance) {
          return payment.markAsFraud(result, function() {
            return callback(null, "Could not process payment - fraud detected - " + (JSON.stringify(result)));
          });
        } else {
          return TransactionHelper.processPayment(payment, callback);
        }
      });
    },
    processPayment: function(payment, callback) {
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
    },
    cancelPayment: function(payment, callback) {
      return Wallet.findUserWalletByCurrency(payment.user_id, payment.currency, function(err, wallet) {
        var totalWithdrawalAmount;
        if (err || !wallet) {
          return callback(err);
        }
        totalWithdrawalAmount = parseInt(math.add(MarketHelper.toBignum(wallet.withdrawal_fee), MarketHelper.toBignum(payment.amount)));
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
              return transaction.commit().success(function() {
                callback(null, "" + payment.id + " - removed");
                return usersSocket.send({
                  type: "wallet-balance-changed",
                  user_id: wallet.user_id,
                  eventData: JsonRenderer.wallet(wallet)
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
      var address, category, txId;
      txId = transactionData.txid;
      if (!txId) {
        return callback();
      }
      category = transactionData.category;
      address = transactionData.address;
      if (!Transaction.isValidFormat(category)) {
        return callback();
      }
      return Wallet.findByAddress(address, function(err, wallet) {
        return Transaction.addFromWallet(transactionData, currency, wallet, function(err) {
          return Transaction.findByTxid(txId, function(err, updatedTransaction) {
            if (wallet) {
              usersSocket.send({
                type: "transaction-update",
                user_id: updatedTransaction.user_id,
                eventData: JsonRenderer.transaction(updatedTransaction)
              });
              if (category !== "receive" || updatedTransaction.balance_loaded || !GLOBAL.wallets[currency].isBalanceConfirmed(updatedTransaction.confirmations)) {
                return callback();
              }
              return GLOBAL.db.sequelize.transaction(function(mysqlTransaction) {
                return wallet.addBalance(updatedTransaction.amount, mysqlTransaction, function(err) {
                  if (err) {
                    return mysqlTransaction.rollback().success(function() {
                      console.error("Could not load user balance " + updatedTransaction.amount + " - " + err);
                      return callback();
                    });
                  }
                  return Transaction.markAsLoaded(updatedTransaction.id, mysqlTransaction, function(err) {
                    if (err) {
                      return mysqlTransaction.rollback().success(function() {
                        console.error("Could not mark the transaction as loaded " + updatedTransaction.id + " - " + err);
                        return callback();
                      });
                    }
                    return mysqlTransaction.commit().success(function() {
                      callback();
                      return usersSocket.send({
                        type: "wallet-balance-loaded",
                        user_id: wallet.user_id,
                        eventData: JsonRenderer.wallet(wallet)
                      });
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
