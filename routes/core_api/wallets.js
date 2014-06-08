(function() {
  var MarketHelper, WalletHealth, restify;

  WalletHealth = GLOBAL.db.WalletHealth;

  MarketHelper = require("../../lib/market_helper");

  restify = require("restify");

  module.exports = function(app) {
    app.post("/create_account/:account/:currency", function(req, res, next) {
      var account, currency;
      account = req.params.account;
      currency = req.params.currency;
      if (!GLOBAL.wallets[currency]) {
        return next(new restify.ConflictError("Wrong Currency."));
      }
      return GLOBAL.wallets[currency].generateAddress(account, function(err, address) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return next(new restify.ConflictError("Could not generate address."));
        }
        return res.send({
          account: account,
          address: address
        });
      });
    });
    app.get("/wallet_balance/:currency", function(req, res, next) {
      var currency;
      currency = req.params.currency;
      if (!GLOBAL.wallets[currency]) {
        return next(new restify.ConflictError("Wallet down or does not exist."));
      }
      return GLOBAL.wallets[currency].getBankBalance(function(err, balance) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return next(new restify.ConflictError("Wallet inaccessible."));
        }
        return res.send({
          currency: currency,
          balance: balance
        });
      });
    });
    app.get("/wallet_info/:currency", function(req, res, next) {
      var currency;
      currency = req.params.currency;
      if (!GLOBAL.wallets[currency]) {
        return next(new restify.ConflictError("Wallet down or does not exist."));
      }
      return GLOBAL.wallets[currency].getInfo(function(err, info) {
        if (err) {
          console.error(err);
        }
        if (err) {
          return next(new restify.ConflictError("Wallet inaccessible."));
        }
        return res.send({
          currency: currency,
          info: info,
          address: GLOBAL.appConfig().wallets[currency.toLowerCase()].wallet.address
        });
      });
    });
    return app.get("/wallet_health/:currency", function(req, res, next) {
      var currency, wallet, walletInfo;
      currency = req.params.currency;
      if (!GLOBAL.wallets[currency]) {
        return next(new restify.ConflictError("Wallet down or does not exist."));
      }
      wallet = GLOBAL.wallets[currency];
      walletInfo = {};
      return wallet.getInfo(function(err, info) {
        if (err || !info) {
          console.error(err);
          walletInfo.status = "error";
          walletInfo.currency = currency;
          walletInfo.blocks = null;
          walletInfo.connections = null;
          walletInfo.balance = null;
          walletInfo.lastUpdated = null;
          return WalletHealth.updateFromWalletInfo(walletInfo, function(err, result) {
            if (err) {
              return next(new restify.ConflictError("Can't update wallet health from walletInfo"));
            }
            return res.send({
              message: "Wallet health check performed on " + (new Date()),
              result: result
            });
          });
        }
        walletInfo.currency = currency;
        walletInfo.blocks = info.blocks;
        walletInfo.connections = info.connections;
        walletInfo.balance = MarketHelper.toBigint(info.balance);
        return wallet.getBestBlock(function(err, lastBlock) {
          var lastUpdated;
          lastUpdated = err || !lastBlock ? NaN : lastBlock.time * 1000;
          walletInfo.last_updated = new Date(lastUpdated);
          walletInfo.status = MarketHelper.getWalletLastUpdatedStatus(walletInfo.last_updated);
          return WalletHealth.updateFromWalletInfo(walletInfo, function(err, result) {
            if (err) {
              return next(new restify.ConflictError("Can't update wallet health from walletInfo"));
            }
            return res.send({
              message: "Wallet health check performed on " + (new Date()),
              result: result
            });
          });
        });
      });
    });
  };

}).call(this);
