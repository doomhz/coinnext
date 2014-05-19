CryptoWallet = require "../crypto_wallet"
bankcoin = require("node-bankcoin")

class BankWallet extends CryptoWallet

  currency: "BANK"

  initialCurrency: "BANK"

  currencyName: "Bankcoin"

  createClient: (options)->
    super options
    @client = new bankcoin.Client options.client

exports = module.exports = BankWallet