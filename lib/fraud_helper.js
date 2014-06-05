(function() {
  var FraudHelper, MarketHelper, Order, Payment, Transaction, Wallet, async, exports, math;

  Wallet = GLOBAL.db.Wallet;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  Order = GLOBAL.db.Order;

  MarketHelper = require("./market_helper");

  async = require("async");

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  FraudHelper = {
    checkWalletBalance: function(walletId, callback) {
      return Wallet.findById(walletId, function(err, wallet) {
        if (err) {
          return callback(err);
        }
        if (!wallet) {
          return callback("Wallet not found.");
        }
        return Transaction.findTotalReceivedByUserAndWallet(wallet.user_id, wallet.id, function(err, totalReceived) {
          if (err) {
            return callback(err);
          }
          return Payment.findTotalPayedByUserAndWallet(wallet.user_id, wallet.id, function(err, totalPayed) {
            var closedOptions, openOptions;
            if (err) {
              return callback(err);
            }
            closedOptions = {
              status: "completed",
              user_id: wallet.user_id,
              currency1: wallet.currency,
              include_logs: true
            };
            openOptions = {
              status: "open",
              action: "sell",
              user_id: wallet.user_id,
              currency1: wallet.currency,
              include_logs: true
            };
            return Order.findByOptions(closedOptions, function(err, closedOrders) {
              return Order.findByOptions(openOptions, function(err, openOrders) {
                var closedOrder, closedOrdersBalance, finalBalance, openOrder, openOrdersBalance, result, _i, _j, _len, _len1;
                closedOrdersBalance = 0;
                openOrdersBalance = 0;
                for (_i = 0, _len = closedOrders.length; _i < _len; _i++) {
                  closedOrder = closedOrders[_i];
                  if (closedOrder.action === "sell") {
                    closedOrdersBalance -= closedOrder.calculateSpentFromLogs();
                  } else {
                    closedOrdersBalance += closedOrder.calculateReceivedFromLogs();
                  }
                }
                for (_j = 0, _len1 = openOrders.length; _j < _len1; _j++) {
                  openOrder = openOrders[_j];
                  openOrdersBalance += closedOrder.calculateSpentFromLogs();
                }
                finalBalance = math.select(totalReceived).add(closedOrdersBalance).add(-wallet.hold_balance).add(-totalPayed).done();
                result = {
                  total_received: MarketHelper.fromBigint(totalReceived),
                  total_payed: MarketHelper.fromBigint(totalPayed),
                  total_closed: MarketHelper.fromBigint(closedOrdersBalance),
                  balance: MarketHelper.fromBigint(wallet.balance),
                  hold_balance: MarketHelper.fromBigint(wallet.hold_balance),
                  final_balance: MarketHelper.fromBigint(finalBalance),
                  valid_final_balance: finalBalance === wallet.balance
                };
                return callback(err, result);
              });
            });
          });
        });
      });
    }
  };

  exports = module.exports = FraudHelper;

}).call(this);
