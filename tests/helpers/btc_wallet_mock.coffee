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
    category: "send"
  }]
transactionsData = [
  {
    amount: 1
    txid: "unique_tx_id"
    confirmations: 6
    time: trTime
    account:  "account"
    fee:      0.0001
    address:  "address"
    category: "receive"
  }
]

class BtcWallet
  confirmations: 6

  getTransaction: (txId, callback)->
    callback null, transactionData
  getTransactions: (account = "*", limit = 100, from = 0, callback)->
    callback null, transactionsData
  getBalance: (account, callback)->
    callback null, 1
  chargeAccount: (account, balance, callback)->
    callback null, true
  sendToAddress: (address, amount, callback)->
    callback null, "unique_tx_id_#{address}"
  isBalanceConfirmed: (existentConfirmations)->
    existentConfirmations >= @confirmations

exports = module.exports = BtcWallet