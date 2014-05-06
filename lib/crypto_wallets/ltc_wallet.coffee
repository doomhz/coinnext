CryptoWallet = require "../crypto_wallet"
litecoin = require("litecoin")

class LtcWallet extends CryptoWallet

  currency: "LTC"

  initialCurrency: "LTC"

  currencyName: "Litecoin"

  createClient: (options)->
    super options
    @client = new litecoin.Client options.client

exports = module.exports = LtcWallet