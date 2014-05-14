CryptoWallet = require "../crypto_wallet"
blackcoin = require("node-blackcoin")

class BcWallet extends CryptoWallet

  currency: "BC"

  initialCurrency: "BC"

  currencyName: "Blackcoin"

  createClient: (options)->
    @client = new blackcoin.Client options.client

exports = module.exports = BcWallet