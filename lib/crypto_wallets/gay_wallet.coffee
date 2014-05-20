CryptoWallet = require "../crypto_wallet"
homocoin = require("node-homocoin")

class GayWallet extends CryptoWallet

  currency: "GAY"

  initialCurrency: "GAY"

  currencyName: "Homocoin"

  createClient: (options)->
    super options
    @client = new homocoin.Client options.client

exports = module.exports = GayWallet