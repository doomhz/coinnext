CryptoWallet = require "./crypto_wallet"
litecoin = require("litecoin")

class LtcWallet extends CryptoWallet

  currency: "LTC"

  createClient: (options)->
    @client = new litecoin.Client options.client

exports = module.exports = LtcWallet