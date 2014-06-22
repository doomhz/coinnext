(function() {
  var FraudHelper, MarketHelper, Order, Payment, Transaction, Wallet, async, exports, math;

  Wallet = GLOBAL.db.Wallet;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  Order = GLOBAL.db.Order;

  MarketHelper = require("./market_helper");

  async = require("async");

  math = require("./math");

  FraudHelper = {
    checkWalletBalance: function(walletId, callback) {
      return Wallet.findById(walletId, function(err, wallet) {
        if (err) {
          return callback(err);
        }
        if (!wallet) {
          return callback("Wallet not found.");
        }
        return FraudHelper.checkBalances(wallet, callback);
      });
    },
    checkUserBalances: function(userId, callback) {
      return Wallet.findUserWalletByCurrency(userId, "BTC", function(err, wallet) {
        if (err) {
          return callback(err);
        }
        if (!wallet) {
          return callback("Wallet not found.");
        }
        return FraudHelper.checkBalances(wallet, callback);
      });
    },
    checkBalances: function(wallet, callback) {
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
            status: ["completed", "partiallyCompleted"],
            user_id: wallet.user_id,
            currency1: wallet.currency,
            include_logs: true,
            include_deleted: true
          };
          openOptions = {
            status: ["open", "partiallyCompleted"],
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
                  if (closedOrder.sell_currency === wallet.currency) {
                    closedOrdersBalance = parseInt(math.subtract(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateSpentFromLogs())));
                  }
                  if (closedOrder.buy_currency === wallet.currency) {
                    closedOrdersBalance = parseInt(math.add(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateReceivedFromLogs())));
                  }
                }
                if (closedOrder.action === "buy") {
                  if (closedOrder.buy_currency === wallet.currency) {
                    closedOrdersBalance = parseInt(math.add(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateReceivedFromLogs())));
                  }
                  if (closedOrder.sell_currency === wallet.currency) {
                    closedOrdersBalance = parseInt(math.subtract(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateSpentFromLogs())));
                  }
                }
              }
              for (_j = 0, _len1 = openOrders.length; _j < _len1; _j++) {
                openOrder = openOrders[_j];
                if (openOrder.sell_currency === wallet.currency) {
                  openOrdersBalance = parseInt(math.add(MarketHelper.toBignum(openOrdersBalance), MarketHelper.toBignum(openOrder.left_hold_balance)));
                }
              }
              finalBalance = parseInt(math.select(MarketHelper.toBignum(totalReceived)).add(MarketHelper.toBignum(closedOrdersBalance)).subtract(MarketHelper.toBignum(wallet.hold_balance)).subtract(MarketHelper.toBignum(totalPayed)).done());
              result = {
                total_received: MarketHelper.fromBigint(totalReceived),
                total_payed: MarketHelper.fromBigint(totalPayed),
                total_closed: MarketHelper.fromBigint(closedOrdersBalance),
                total_open: MarketHelper.fromBigint(openOrdersBalance),
                balance: MarketHelper.fromBigint(wallet.balance),
                hold_balance: MarketHelper.fromBigint(wallet.hold_balance),
                final_balance: MarketHelper.fromBigint(finalBalance),
                valid_final_balance: finalBalance === wallet.balance,
                valid_hold_balance: openOrdersBalance === wallet.hold_balance
              };
              return callback(err, result);
            });
          });
        });
      });
    }
  };

  exports = module.exports = FraudHelper;

}).call(this);
