CryptoWallet = require "../crypto_wallet"
tacocoin = require("node-tacocoin")

class TcoWallet extends CryptoWallet

  currency: "TCO"

  initialCurrency: "TCO"

  currencyName: "Tacocoin"

  createClient: (options)->
    super options
    @client = new tacocoin.Client options.client

exports = module.exports = TcoWallet