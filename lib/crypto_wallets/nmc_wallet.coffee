CryptoWallet = require "../crypto_wallet"
namecoin = require("namecoin")

class NmcWallet extends CryptoWallet

  currency: "NMC"

  initialCurrency: "NMC"

  currencyName: "Namecoin"

  createClient: (options)->
    super options
    @client = new namecoin.Client options.client

exports = module.exports = NmcWallet