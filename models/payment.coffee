PaymentSchema = new Schema
  user_id:
    type: String
    index: true
  wallet_id:
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

PaymentSchema.methods.process = (callback = ()->)->
  @status = "processed"
  @save callback

PaymentSchema.methods.cancel = (reason, callback = ()->)->
  @status = "canceled"
  @log.push reason
  @save callback

Payment = mongoose.model("Payment", PaymentSchema)
exports = module.exports = Payment