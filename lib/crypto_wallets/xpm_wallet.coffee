CryptoWallet = require "../crypto_wallet"
primecoin = require("node-primecoin")

class XpmWallet extends CryptoWallet

  currency: "XPM"

  initialCurrency: "XPM"

  currencyName: "Primecoin"

  createClient: (options)->
    super options
    @client = new primecoin.Client options.client

exports = module.exports = XpmWallet