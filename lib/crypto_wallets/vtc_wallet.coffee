CryptoWallet = require "../crypto_wallet"
vertcoin = require("node-vertcoin")

class VtcWallet extends CryptoWallet

  currency: "VTC"

  initialCurrency: "VTC"

  currencyName: "Vertcoin"

  createClient: (options)->
    super options
    @client = new vertcoin.Client options.client

exports = module.exports = VtcWallet