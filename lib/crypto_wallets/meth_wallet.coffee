CryptoWallet = require "../crypto_wallet"
cryptometh = require("node-cryptometh")

class MethWallet extends CryptoWallet

  currency: "METH"

  initialCurrency: "METH"

  currencyName: "Cryptometh"

  createClient: (options)->
    super options
    @client = new cryptometh.Client options.client

exports = module.exports = MethWallet