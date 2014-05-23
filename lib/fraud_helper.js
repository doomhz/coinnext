(function() {
  var FraudHelper, MarketHelper, async, exports, math;

  MarketHelper = require("./market_helper");

  async = require("async");

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  FraudHelper = {
    findDesyncedWallets: function(callback) {
      return GLOBAL.db.Wallet.findAll({
        where: {
          address: {
            ne: null
          }
        }
      }).complete(function(err, wallets) {
        return async.mapSeries(wallets, FraudHelper.checkProperBalance, function(err, result) {
          return callback(err, result);
        });
      });
    },
    checkProperBalance: function(wallet, cb) {
      return GLOBAL.db.Transaction.findProcessedByUserAndWallet(wallet.user_id, wallet.id, function(err, transactions) {
        return GLOBAL.db.Payment.findByUserAndWallet(wallet.user_id, wallet.id, "processed", function(err, payments) {
          var options;
          options = {
            status: "open",
            user_id: wallet.user_id,
            sell_currency: wallet.sell_currency
          };
          return GLOBAL.db.Order.findByOptions(options, function(err, orders) {
            var order, payment, totalAvailableBalance, totalBalance, totalDeposit, totalHoldBalance, totalWithdrawal, transaction, _i, _j, _k, _len, _len1, _len2;
            totalDeposit = 0;
            totalWithdrawal = 0;
            totalHoldBalance;
            for (_i = 0, _len = transactions.length; _i < _len; _i++) {
              transaction = transactions[_i];
              if (transaction.category === "receive") {
                totalDeposit = math.add(totalDeposit, transaction.amount);
              }
            }
            for (_j = 0, _len1 = payments.length; _j < _len1; _j++) {
              payment = payments[_j];
              totalWithdrawal = math.add(totalWithdrawal, payment.amount);
            }
            for (_k = 0, _len2 = orders.length; _k < _len2; _k++) {
              order = orders[_k];
              try {
                totalHoldBalance = math.add(totalHoldBalance, order.left_hold_balance);
              } catch (_error) {

              }
            }
            totalBalance = math.add(totalDeposit, -totalWithdrawal);
            totalAvailableBalance = math.add(totalBalance, -totalHoldBalance);
            if (totalAvailableBalance === wallet.balance && totalHoldBalance === wallet.hold_balance) {
              return cb();
            }
            return cb({
              wallet_id: wallet.id,
              user_id: wallet.user_id,
              currency: wallet.currency,
              current: {
                balance: wallet.balance,
                hold_balance: wallet.hold_balance
              },
              fixed: {
                balance: totalAvailableBalance,
                hold_balance: totalHoldBalance
              }
            });
          });
        });
      });
    }
  };

  exports = module.exports = FraudHelper;

}).call(this);
