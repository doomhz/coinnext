CryptoWallet = require "./crypto_wallet"
peercoin = require("node-peercoin")

class PpcWallet extends CryptoWallet

  currency: "PPC"

  createClient: (options)->
    @client = new peercoin.Client options.client

exports = module.exports = PpcWallet