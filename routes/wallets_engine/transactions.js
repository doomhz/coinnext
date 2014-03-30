(function() {
  var JsonRenderer, Payment, Transaction, TransactionHelper, Wallet, async, paymentsProcessedUserIds, restify;

  restify = require("restify");

  async = require("async");

  Wallet = GLOBAL.db.Wallet;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  JsonRenderer = require("../../lib/json_renderer");

  TransactionHelper = require("../../lib/transaction_helper");

  paymentsProcessedUserIds = [];

  module.exports = function(app) {
    app.put("/transaction/:currency/:tx_id", function(req, res, next) {
      var currency, txId;
      txId = req.params.tx_id;
      currency = req.params.currency;
      console.log(txId);
      console.log(currency);
      return TransactionHelper.loadTransaction(txId, currency, function() {
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
    app.post("/process_pending_payments", function(req, res, next) {
      TransactionHelper.paymentsProcessedUserIds = [];
      return Payment.findByStatus("pending", function(err, payments) {
        return async.mapSeries(payments, TransactionHelper.processPayment, function(err, result) {
          if (err) {
            console.log(err);
          }
          return res.send("" + (new Date()) + " - " + result);
        });
      });
    });
    return app.post("/process_payment/:payment_id", function(req, res, next) {
      var paymentId;
      paymentId = req.params.payment_id;
      TransactionHelper.paymentsProcessedUserIds = [];
      return Payment.findById(paymentId, function(err, payment) {
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
  };

}).call(this);
