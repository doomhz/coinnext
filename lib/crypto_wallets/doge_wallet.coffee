CryptoWallet = require "../crypto_wallet"

class DogeWallet extends CryptoWallet

  getBalance: (account, callback)->
    @client.getBalance account, (err, balance)=>
      balance = if balance.result? then balance.result else balance
      balance = @convert @initialCurrency, @currency, balance
      callback(err, balance) if callback

exports = module.exports = DogeWallet