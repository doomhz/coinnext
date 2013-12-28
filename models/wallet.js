(function() {
  var CURRENCIES, Wallet, WalletSchema, exports, _;

  _ = require("underscore");

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

  WalletSchema.virtual("account").get(function() {
    return "wallet_" + this._id;
  });

  WalletSchema.methods.generateAddress = function(callback) {
    var _this = this;
    if (callback == null) {
      callback = function() {};
    }
    return GLOBAL.walletsClient.send("create_account", [this.account, this.currency], function(err, res, body) {
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

  WalletSchema.methods.addBalance = function(newBalance, callback) {
    var _this = this;
    if (callback == null) {
      callback = function() {};
    }
    if (!_.isNaN(newBalance) && _.isNumber(newBalance)) {
      return Wallet.update({
        _id: this._id
      }, {
        $inc: {
          balance: newBalance
        }
      }, function(err) {
        if (err) {
          console.log("Could not add the wallet balance " + newBalance + " for " + _this._id + ": " + err);
        }
        return Wallet.findById(_this._id, function(err, wl) {
          return callback(err, pl);
        });
      });
    } else {
      console.log("Could not add wallet balance " + newBalance + " for " + this._id);
      return callback(null, this);
    }
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
