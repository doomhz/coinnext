CryptoWallet = require "../crypto_wallet"
xtracoin = require("node-xtracoin")

class CxWallet extends CryptoWallet

  currency: "CX"

  initialCurrency: "CX"

  currencyName: "Xtracoin"

  createClient: (options)->
    super options
    @client = new xtracoin.Client options.client

exports = module.exports = CxWallet