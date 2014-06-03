_ = require "underscore"
trTime          = Date.now() / 1000
transactionData =
  amount: 1
  txid: "unique_tx_id"
  confirmations: 6
  time: trTime
  details: []
transactionDetails =
  account:  "account"
  fee:      0.0001
  address:  "address"
  category: "receive"
transactionsData =
  amount: 1
  txid: "unique_tx_id"
  confirmations: 6
  time: trTime
  account:  "account"
  fee:      0.0001
  address:  "address"
  category: "receive"

class BtcWallet
  confirmations: 6

  getTransaction: (txId, callback)->
    tr = _.clone transactionData
    tr.details = [_.clone(transactionDetails)]
    callback null, tr
  getTransactions: (account = "*", limit = 100, from = 0, callback)->
    callback null, [_.clone(transactionsData)]
  getBalance: (account, callback)->
    callback null, 1
  chargeAccount: (account, balance, callback)->
    callback null, true
  sendToAddress: (address, amount, callback)->
    callback null, "unique_tx_id_#{address}"
  isBalanceConfirmed: (existentConfirmations)->
    existentConfirmations >= @confirmations

exports = module.exports = BtcWallet