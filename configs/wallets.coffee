MarketHelper = require "../lib/market_helper"

wallets = {}

for currency of MarketHelper.getCurrencies()
  if process.env.NODE_ENV is "test"
    try
      Wallet = require "../tests/helpers/#{currency.toLowerCase()}_wallet_mock"
    catch
  else
    Wallet = require "../lib/crypto_wallets/#{currency.toLowerCase()}_wallet"
  wallets[currency] = new Wallet()

exports = module.exports = wallets