CryptoWallet = require "../crypto_wallet"
darkcoin = require("node-darkcoin")

class DrkWallet extends CryptoWallet

  currency: "DRK"

  initialCurrency: "DRK"

  currencyName: "Darkcoin"

  createClient: (options)->
    super options
    @client = new darkcoin.Client options.client

exports = module.exports = DrkWallet