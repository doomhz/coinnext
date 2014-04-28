MarketHelper = require "../../lib/market_helper"
markets = []
for literal, int of MarketHelper.getMarkets()
  markets.push {type: literal, status: "enabled"}
module.exports = markets