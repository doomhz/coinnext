(function() {
  var JsonRenderer, Payment, Transaction, TransactionHelper, Wallet, async, paymentsProcessedUserIds, restify, _;

  restify = require("restify");

  async = require("async");

  Wallet = GLOBAL.db.Wallet;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  JsonRenderer = require("../../lib/json_renderer");

  TransactionHelper = require("../../lib/transaction_helper");

  paymentsProcessedUserIds = [];

  _ = require("underscore");

  module.exports = function(app) {
    app.put("/transaction/:currency/:tx_id", function(req, res, next) {
      var currency, txId;
      txId = req.params.tx_id;
      currency = req.params.currency;
      return GLOBAL.wallets[currency].getTransaction(txId, function(err, walletTransaction) {
        var loadTransactionCallback, subTransactions;
        subTransactions = _.clone(walletTransaction.details);
        delete walletTransaction.details;
        loadTransactionCallback = function(subTransaction, callback) {
          var transactionData;
          transactionData = _.extend(subTransaction, walletTransaction);
          return TransactionHelper.loadTransaction(transactionData, currency, callback);
        };
        return async.mapSeries(subTransactions, loadTransactionCallback, function(err, result) {
          if (err) {
            console.error(err);
          }
          return res.send("" + (new Date()) + " - Added transaction " + txId + " " + currency);
        });
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
          return TransactionHelper.loadTransaction(transaction, currency, callback);
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
    app.post("/create_payment", function(req, res, next) {
      var data;
      data = req.body;
      return TransactionHelper.createPayment(data, function(err, payment) {
        if (err) {
          return next(new restify.ConflictError(err));
        }
        return res.json(JsonRenderer.payment(payment));
      });
    });
    app.post("/process_pending_payments", function(req, res, next) {
      TransactionHelper.paymentsProcessedUserIds = [];
      return Payment.findToProcess(function(err, payments) {
        return async.mapSeries(payments, TransactionHelper.processPaymentWithFraud, function(err, result) {
          if (err) {
            console.log(err);
          }
          return res.send("" + (new Date()) + " - " + result);
        });
      });
    });
    app.put("/process_payment/:payment_id", function(req, res, next) {
      var paymentId;
      paymentId = req.params.payment_id;
      TransactionHelper.paymentsProcessedUserIds = [];
      return Payment.findNonProcessedById(paymentId, function(err, payment) {
        if (!payment) {
          return next(new restify.ConflictError("Could not find non processed payment " + paymentId));
        }
        return TransactionHelper.processPayment(payment, function(err, result) {
          return Payment.findById(paymentId, function(err, processedPayment) {
            res.send({
              paymentId: paymentId,
              status: processedPayment.status,
              result: result
            });
            if (processedPayment.isProcessed()) {
              return TransactionHelper.pushToUser({
                type: "payment-processed",
                user_id: payment.user_id,
                eventData: JsonRenderer.payment(processedPayment)
              });
            }
          });
        });
      });
    });
    return app.del("/cancel_payment/:payment_id", function(req, res, next) {
      var paymentId;
      paymentId = req.params.payment_id;
      return Payment.findById(paymentId, function(err, payment) {
        if (payment.isProcessed()) {
          return next(new restify.ConflictError("Could not cancel already processed payment " + paymentId + "."));
        }
        return TransactionHelper.cancelPayment(payment, function(err, result) {
          if (err) {
            return next(new restify.ConflictError("Could not cancel already payment " + paymentId + " - " + err));
          }
          return res.send({
            paymentId: paymentId,
            status: "removed"
          });
        });
      });
    });
  };

}).call(this);
