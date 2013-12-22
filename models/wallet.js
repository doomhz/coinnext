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
      index: true
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

  WalletSchema.methods.generateAddress = function(userId, callback) {
    var _this = this;
    if (callback == null) {
      callback = function() {};
    }
    return GLOBAL.walletsClient.send("create_account", [userId, this.currency], function(err, res, body) {
      if (err) {
        console.error(err);
        return callback(err, res, body);
      }
      if (body && body.address) {
        _this.address = body.address;
        return _this.save(callback);
      } else {
        return callback("Invalid address");
      }
    });
  };

  WalletSchema.methods.canWithdraw = function(amount) {
    return parseFloat(this.balance) >= parseFloat(amount);
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
      created: "asc"
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
