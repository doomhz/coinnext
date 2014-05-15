CryptoWallet = require "../crypto_wallet"
guldencoin = require("node-guldencoin")

class NlgWallet extends CryptoWallet

  currency: "NLG"

  initialCurrency: "NLG"

  currencyName: "Guldencoin"

  createClient: (options)->
    super options
    @client = new guldencoin.Client options.client

exports = module.exports = NlgWallet