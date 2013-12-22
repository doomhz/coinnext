(function() {
  var CURRENCIES, Wallet, WalletSchema, exports;

  CURRENCIES = ["BTC", "LTC", "PPC", "WDC", "NMC", "QRK", "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"];

  WalletSchema = new Schema({
    user_id: {
      type: String,
      index: true
    },
    currency: {
      type: String,
      "enum": CURRENCIES,
      index: true
    },
    address: {
      type: String,
      index: {
        unique: true
      }
    },
    balance: {
      type: Number,
      "default": 0,
      index: true
    },
    created:  ({
      type: Date ,
      "default": Date.now ,
      index: true
    })
  });

  WalletSchema.set("autoIndex", false);

  WalletSchema.methods.generateAddress = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.address = "new_address_" + this.id;
    return this.save(callback);
  };

  WalletSchema.statics.getCurrencies = function() {
    return CURRENCIES;
  };

  WalletSchema.statics.findUserWalletByCurrency = function(userId, currency, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return Wallet.findOne({
      user_id: userId,
      currency: currency
    }, callback);
  };

  WalletSchema.statics.findUserWallets = function(userId, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return Wallet.find({
      user_id: userId
    }).sort({
      created: "desc"
    }).exec(callback);
  };

  WalletSchema.statics.findUserWallet = function(userId, walletId, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return Wallet.findOne({
      user_id: userId,
      _id: walletId
    }, callback);
  };

  Wallet = mongoose.model("Wallet", WalletSchema);

  exports = module.exports = Wallet;

}).call(this);
