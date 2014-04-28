(function() {
  var MarketHelper, int, literal, markets, _ref;

  MarketHelper = require("../../lib/market_helper");

  markets = [];

  _ref = MarketHelper.getMarkets();
  for (literal in _ref) {
    int = _ref[literal];
    markets.push({
      type: literal,
      status: "enabled"
    });
  }

  module.exports = markets;

}).call(this);
