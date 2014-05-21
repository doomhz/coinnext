(function() {
  var MarketHelper, Wallet, currency, exports, fs, options, path, walletType, wallets;

  fs = require("fs");

  MarketHelper = require("../lib/market_helper");

  wallets = {};

  for (currency in MarketHelper.getCurrencies()) {
    walletType = currency.toLowerCase();
    options = process.env.NODE_ENV !== "production" && (GLOBAL.appConfig().wallets[walletType] == null) ? GLOBAL.appConfig().wallets["btc"] : GLOBAL.appConfig().wallets[walletType];
    if (process.env.NODE_ENV === "test") {
      path = "" + (process.cwd()) + "/tests/helpers/" + walletType + "_wallet_mock.js";
      if (fs.existsSync(path)) {
        Wallet = require(path);
        wallets[currency] = new Wallet(options);
      }
    } else {
      path = "" + (process.cwd()) + "/lib/crypto_wallets/" + walletType + "_wallet.js";
      if (fs.existsSync(path)) {
        Wallet = require(path);
      } else {
        Wallet = require("../lib/crypto_wallet");
      }
      wallets[currency] = new Wallet(options);
    }
  }

  exports = module.exports = wallets;

}).call(this);
