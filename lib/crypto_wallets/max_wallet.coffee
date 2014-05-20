CryptoWallet = require "../crypto_wallet"
maxcoin = require("node-maxcoin")

class MaxWallet extends CryptoWallet

  currency: "MAX"

  initialCurrency: "MAX"

  currencyName: "Maxcoin"

  createClient: (options)->
    super options
    @client = new maxcoin.Client options.client

exports = module.exports = MaxWallet