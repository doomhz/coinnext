CryptoWallet = require "./crypto_wallet"
dogecoin = require("node-dogecoin")

class DogeWallet extends CryptoWallet

  currency: "DOGE"

  createClient: (options)->
    @client = dogecoin options.client

exports = module.exports = DogeWallet