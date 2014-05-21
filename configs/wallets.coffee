fs = require "fs"
MarketHelper = require "../lib/market_helper"

wallets = {}

for currency of MarketHelper.getCurrencies()
  walletType = currency.toLowerCase()
  options = if process.env.NODE_ENV isnt "production" and not GLOBAL.appConfig().wallets[walletType]? then GLOBAL.appConfig().wallets["btc"] else GLOBAL.appConfig().wallets[walletType]
  if process.env.NODE_ENV is "test"
    path = "#{process.cwd()}/tests/helpers/#{walletType}_wallet_mock.js"
    if fs.existsSync path
      Wallet = require path
      wallets[currency] = new Wallet options
  else
    path = "#{process.cwd()}/lib/crypto_wallets/#{walletType}_wallet.js"
    if fs.existsSync path
      Wallet = require path
    else
      Wallet = require "../lib/crypto_wallet"
    wallets[currency] = new Wallet options

exports = module.exports = wallets