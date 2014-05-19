CryptoWallet = require "../crypto_wallet"
bitraam = require("node-bitraam")

class BrmWallet extends CryptoWallet

  currency: "BRM"

  initialCurrency: "BRM"

  currencyName: "Bitraam"

  createClient: (options)->
    super options
    @client = new bitraam.Client options.client

exports = module.exports = BrmWallet