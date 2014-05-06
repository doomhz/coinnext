CryptoWallet = require "../crypto_wallet"
bitcoin = require("bitcoin")

class BtcWallet extends CryptoWallet

  currency: "BTC"

  initialCurrency: "BTC"

  currencyName: "Bitcoin"

  createClient: (options)->
    super options
    @client = new bitcoin.Client options.client

exports = module.exports = BtcWallet