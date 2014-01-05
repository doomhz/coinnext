PaymentSchema = new Schema
  user_id:
    type: String
    index: true
  wallet_id:
    type: String
    index: true
  transaction_id:
    type: String
    index: true
  currency:
    type: String
    index: true
  address:
    type: String
  amount:
    type: Number
    default: 0
  status:
    type: String
    enum: ["pending", "processed", "canceled"]
    default: "pending"
  log:
    type: [String]
    default: []
  remote_ip:
    type: String
  updated:
    type: Date
    default: Date.now
  created:
    type: Date
    default: Date.now
    index: true

PaymentSchema.methods.isProcessed = ()->
  @status is "processed"

PaymentSchema.methods.isCanceled = ()->
  @status is "canceled"

PaymentSchema.methods.isPending = ()->
  @status is "pending"

PaymentSchema.methods.process = (response, callback = ()->)->
  @status = "processed"
  @transaction_id = response
  @log.push JSON.stringify(response)
  @save callback

PaymentSchema.methods.cancel = (reason, callback = ()->)->
  @status = "canceled"
  reason = JSON.stringify reason
  @log.push reason
  @save (e, p)->
    callback reason, p

PaymentSchema.methods.errored = (reason, callback = ()->)->
  reason = JSON.stringify reason
  @log.push reason
  @save (e, p)->
    callback reason, p

PaymentSchema.statics.findByUserAndWallet = (userId, walletId, status, callback)->
  Payment.find {user_id: userId, wallet_id: walletId, status: status}, callback

Payment = mongoose.model("Payment", PaymentSchema)
exports = module.exports = Payment