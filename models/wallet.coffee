_ = require "underscore"

#CURRENCIES = [
#  "BTC", "LTC", "PPC", "WDC", "NMC", "QRK",
#  "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"
#]

CURRENCIES = [
  "BTC", "LTC", "PPC"
]

CURRENCY_NAMES =
  BTC: "Bitcoin"
  LTC: "Litecoin"
  PPC: "Peercoin"

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
  hold_balance:
    type: Number
    default: 0
    index: true
  fee:
    type: Number
    default: 0.2
  created: 
    type: Date 
    default: Date.now 
    index: true

WalletSchema.set("autoIndex", false)

WalletSchema.virtual("account").get ()->
  "wallet_#{@_id}"

WalletSchema.virtual("currency_name").get ()->
  CURRENCY_NAMES[@currency]

WalletSchema.methods.generateAddress = (callback = ()->)->
  GLOBAL.walletsClient.send "create_account", [@account, @currency], (err, res, body)=>
    if err
      console.error err
      return callback err, res, body
    if body and body.address
      @address = body.address
      @save callback
    else
      console.error "Could not generate address - #{JSON.stringify(body)}"
      callback "Invalid address"

WalletSchema.methods.addBalance = (newBalance, callback = ()->)->
  if not _.isNaN(newBalance) and _.isNumber(newBalance)
    Wallet.update {_id: @_id}, {$inc: {balance: newBalance}}, (err)=>
      console.log "Could not add the wallet balance #{newBalance} for #{@_id}: #{err}"  if err
      Wallet.findById @_id, (err, wl)=>
        callback err, wl
  else
    console.log "Could not add wallet balance #{newBalance} for #{@_id}"
    callback(null, @)

WalletSchema.methods.holdBalance = (balance, callback = ()->)->
  if not _.isNaN(balance) and _.isNumber(balance) and @canWithdraw(balance)
    @addBalance -balance, (err)=>
      if not err
        Wallet.update {_id: @_id}, {$inc: {hold_balance: balance}}, (err)=>
          console.log "Could not add the wallet hold balance #{balance} for #{@_id}: #{err}"  if err
          Wallet.findById @_id, (err, wl)=>
            callback err, wl
      else
        console.log "Could not hold wallet balance #{balance} for #{@_id}, not enough funds?"
        Wallet.findById @_id, (err, wl)=>
          callback err, wl
  else
    console.log "Could not add wallet hold balance #{balance} for #{@_id}"
    callback("Invalid balance #{balance}", @)

WalletSchema.methods.canWithdraw = (amount)->
  parseFloat(@balance) >= parseFloat(amount)

WalletSchema.statics.getCurrencies = ()->
  CURRENCIES

WalletSchema.statics.getCurrencyNames = ()->
  CURRENCY_NAMES

WalletSchema.statics.findUserWalletByCurrency = (userId, currency, callback = ()->)->
  Wallet.findOne {user_id: userId, currency: currency}, callback

WalletSchema.statics.findOrCreateUserWalletByCurrency = (userId, currency, callback = ()->)->
  Wallet.findUserWalletByCurrency userId, currency, (err, existentWallet)->
    if not existentWallet
      newWallet = new Wallet
        user_id: userId
        currency: currency
      newWallet.save callback
    else
      callback err, existentWallet

WalletSchema.statics.findUserWallets = (userId, callback = ()->)->
  Wallet.find({user_id: userId}).sort({created: "desc"}).exec callback

WalletSchema.statics.findUserWallet = (userId, walletId, callback = ()->)->
  Wallet.findOne {user_id: userId, _id: walletId}, callback

WalletSchema.statics.findByAccount = (account, callback = ()->)->
  id = account.replace("wallet_", "")
  Wallet.findById id, callback

WalletSchema.statics.isValidCurrency = (currency)->
  CURRENCIES.indexOf(currency) > -1

Wallet = mongoose.model "Wallet", WalletSchema
exports = module.exports = Wallet