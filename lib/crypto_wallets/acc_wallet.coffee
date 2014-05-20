CryptoWallet = require "../crypto_wallet"
coind = require "node-coind"

class AccWallet extends CryptoWallet

  currency: "ACC"

  initialCurrency: "ACC"

  currencyName: "Antarcticcoin"

  createClient: (options)->
    super options
    @client = new coind.Client options.client

exports = module.exports = AccWallet