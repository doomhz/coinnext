(function() {
  var Transaction, User, Wallet, restify;

  restify = require("restify");

  User = require("../../models/user");

  Wallet = require("../../models/wallet");

  Transaction = require("../../models/transaction");

  module.exports = function(app) {
    app.post("/create_account/:user_id/:currency", function(req, res, next) {
      var currency, userId;
      userId = req.params.user_id;
      currency = req.params.currency;
      if (GLOBAL.wallets[currency]) {
        return GLOBAL.wallets[currency].generateAddress(userId, function(err, address) {
          if (!err) {
            return res.send({
              account: userId,
              address: address
            });
          } else {
            return next(new restify.ConflictError("Could not generate address."));
          }
        });
      } else {
        return next(new restify.ConflictError("Wrong Currency."));
      }
    });
    return app.put("/transaction/:currency/:tx_id", function(req, res, next) {
      var currency, txId;
      txId = req.params.tx_id;
      currency = req.params.currency;
      GLOBAL.wallets[currency].getTransaction(txId, function(err, transaction) {
        if (err) {
          console.error(err);
        }
        if (transaction && transaction.details[0].category !== "move") {
          if (transaction.details[0].account) {
            return User.findById(transaction.details[0].account, function(err, user) {
              if (user) {
                return Wallet.findUserWalletByCurrency(user.id, currency, function(err, wallet) {
                  return Transaction.addFromWallet(transaction, currency, user, wallet);
                });
              } else {
                return Transaction.addFromWallet(transaction, currency, user);
              }
            });
          } else {
            return Transaction.addFromWallet(transaction, currency);
          }
        }
      });
      return res.end();
    });
  };

}).call(this);
