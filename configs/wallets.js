(function() {
  var MarketHelper, Wallet, currency, exports, wallets;

  MarketHelper = require("../lib/market_helper");

  wallets = {};

  for (currency in MarketHelper.getCurrencies()) {
    if (process.env.NODE_ENV === "test") {
      try {
        Wallet = require("../tests/helpers/" + (currency.toLowerCase()) + "_wallet_mock");
      } catch (_error) {

      }
    } else {
      Wallet = require("../lib/crypto_wallets/" + (currency.toLowerCase()) + "_wallet");
    }
    wallets[currency] = new Wallet();
  }

  exports = module.exports = wallets;

}).call(this);
