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
  balance:
    type: Number
    default: 0
    index: true
  created: 
    type: Date 
    default: Date.now 
    index: true

WalletSchema.set("autoIndex", false)

WalletSchema.statics.getCurrencies = ()->
  CURRENCIES

WalletSchema.statics.findUserWalletByCurrency = (userId, currency, callback = ()->)->
  Wallet.findOne {user_id: userId, currency: currency}, callback

WalletSchema.statics.findUserWallets = (userId, callback = ()->)->
  Wallet.find {user_id: userId}, callback

Wallet = mongoose.model "Wallet", WalletSchema
exports = module.exports = Wallet