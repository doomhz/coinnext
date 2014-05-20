CryptoWallet = require "../crypto_wallet"
coind = require "node-coind"

class VrcWallet extends CryptoWallet

  currency: "VRC"

  initialCurrency: "VRC"

  currencyName: "Vericoin"

  createClient: (options)->
    super options
    @client = new coind.Client options.client

exports = module.exports = VrcWallet