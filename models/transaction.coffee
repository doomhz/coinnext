TransactionSchema = new Schema
  user_id:
    type: String
    index: true
  wallet_id:
    type: String
    index: true
  currency:
    type: String
    index: true
  account:
    type: String
  fee:
    type: String
  address:
    type: String
  amount:
    type: Number
  category:
    type: String
    index: true
  txid:
    type: String
    index:
      unique: true
  confirmations:
    type: Number
  created:
    type: Date
    default: Date.now
    index: true

TransactionSchema.set("autoIndex", false)

TransactionSchema.statics.addFromWallet = (transactionData, currency, wallet, callback = ()->)->
  details = transactionData.details[0] or {}
  data =
    user_id:       wallet.user_id  if wallet
    wallet_id:     wallet._id  if wallet
    currency:      currency
    account:       details.account
    fee:           details.fee
    address:       details.address
    category:      details.category
    amount:        transactionData.amount
    txid:          transactionData.txid
    confirmations: transactionData.confirmations
    created:       new Date(transactionData.time * 1000)
  for key of data
    delete data[key]  if not data[key]
  Transaction.findOneAndUpdate {txid: data.txid}, data, {upsert: true}, callback

Transaction = mongoose.model("Transaction", TransactionSchema)
exports = module.exports = Transaction