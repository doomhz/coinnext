CURRENCIES = [
  "BTC", "LTC", "PPC", "WDC", "NMC", "QRK",
  "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"
]

WalletSchema = new Schema
  user_id:
    type: String
    index: true
  currency:
    type: String
    enum: CURRENCIES
    index: true
  address:
    type: String
    index: true
  balance:
    type: Number
    default: 0
    index: true
  created: 
    type: Date 
    default: Date.now 
    index: true

WalletSchema.set("autoIndex", false)

WalletSchema.methods.generateAddress = (userId, callback = ()->)->
  GLOBAL.walletsClient.send "create_account", [userId, @currency], (err, res, body)=>
    if err
      console.error err
      return callback err, res, body
    if body and body.address
      @address = body.address
      @save callback
    else
      callback "Invalid address"

WalletSchema.methods.syncBalance = ()->
  #TODO: Implement

WalletSchema.methods.addBalance = ()->
  #TODO: Implement

WalletSchema.methods.canWithdraw = (amount)->
  parseFloat(@balance) >= parseFloat(amount)

WalletSchema.statics.getCurrencies = ()->
  CURRENCIES

WalletSchema.statics.findUserWalletByCurrency = (userId, currency, callback = ()->)->
  Wallet.findOne {user_id: userId, currency: currency}, callback

WalletSchema.statics.findUserWallets = (userId, callback = ()->)->
  Wallet.find({user_id: userId}).sort({created: "asc"}).exec callback

WalletSchema.statics.findUserWallet = (userId, walletId, callback = ()->)->
  Wallet.findOne {user_id: userId, _id: walletId}, callback

Wallet = mongoose.model "Wallet", WalletSchema
exports = module.exports = Wallet