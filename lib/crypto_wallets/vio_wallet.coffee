CryptoWallet = require "../crypto_wallet"
coind = require "node-coind"

class VioWallet extends CryptoWallet

  currency: "VIO"

  initialCurrency: "VIO"

  currencyName: "Violincoin"

  createClient: (options)->
    super options
    @client = new coind.Client options.client

exports = module.exports = VioWallet