CryptoWallet = require "./crypto_wallet"
bitcoin = require("bitcoin")

class BtcWallet extends CryptoWallet

  currency: "BTC"

  createClient: (options)->
    @client = new bitcoin.Client options.client

exports = module.exports = BtcWallet