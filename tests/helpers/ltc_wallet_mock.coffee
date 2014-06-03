trTime          = Date.now() / 1000
transactionData =
  amount: 1
  txid: "unique_tx_id"
  confirmations: 6
  time: trTime
  details: [{
    account:  "account"
    fee:      0.0001
    address:  "address"
    category: "receive"
  }]

class LtcWallet
  
  getTransaction: (txId, callback)->
    callback null, transactionData
  getBalance: (account, callback)->
    callback null, 1
  chargeAccount: (account, balance, callback)->
    callback null, true
  sendToAddress: (address, account, amount, callback)->
    callback null, "unique_tx_id"

exports = module.exports = LtcWallet