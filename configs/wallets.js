(function() {
  var MarketHelper, Wallet, currency, exports, wallets;

  MarketHelper = require("../lib/market_helper");

  wallets = {};

  for (currency in MarketHelper.getCurrencies()) {
    Wallet = process.env.NODE_ENV === "test" ? require("../tests/helpers/" + currency + "_wallet_mock") : require("../lib/crypto_wallets/" + currency + "_wallet");
    wallets[currency] = new Wallet();
  }

  exports = module.exports = wallets;

}).call(this);
