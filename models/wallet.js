(function() {
  var CURRENCIES, CURRENCY_NAMES, Wallet, WalletSchema, exports, _;

  _ = require("underscore");

  CURRENCIES = ["BTC", "LTC", "PPC"];

  CURRENCY_NAMES = {
    BTC: "Bitcoin",
    LTC: "Litecoin",
    PPC: "Peercoin"
  };

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
    hold_balance: {
      type: Number,
      "default": 0,
      index: true
    },
    fee: {
      type: Number,
      "default": 0.002
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

  WalletSchema.virtual("currency_name").get(function() {
    return CURRENCY_NAMES[this.currency];
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
        console.error("Could not generate address - " + (JSON.stringify(body)));
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
          return callback(err, wl);
        });
      });
    } else {
      console.log("Could not add wallet balance " + newBalance + " for " + this._id);
      return callback(null, this);
    }
  };

  WalletSchema.methods.holdBalance = function(balance, callback) {
    var _this = this;
    if (callback == null) {
      callback = function() {};
    }
    if (!_.isNaN(balance) && _.isNumber(balance) && this.canWithdraw(balance)) {
      return this.addBalance(-balance, function(err) {
        if (!err) {
          return Wallet.update({
            _id: _this._id
          }, {
            $inc: {
              hold_balance: balance
            }
          }, function(err) {
            if (err) {
              console.log("Could not add the wallet hold balance " + balance + " for " + _this._id + ": " + err);
            }
            return Wallet.findById(_this._id, function(err, wl) {
              return callback(err, wl);
            });
          });
        } else {
          console.log("Could not hold wallet balance " + balance + " for " + _this._id + ", not enough funds?");
          return Wallet.findById(_this._id, function(err, wl) {
            return callback(err, wl);
          });
        }
      });
    } else {
      console.log("Could not add wallet hold balance " + balance + " for " + this._id);
      return callback("Invalid balance " + balance, this);
    }
  };

  WalletSchema.methods.canWithdraw = function(amount) {
    return parseFloat(this.balance) >= parseFloat(amount);
  };

  WalletSchema.statics.getCurrencies = function() {
    return CURRENCIES;
  };

  WalletSchema.statics.getCurrencyNames = function() {
    return CURRENCY_NAMES;
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

  WalletSchema.statics.findOrCreateUserWalletByCurrency = function(userId, currency, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return Wallet.findUserWalletByCurrency(userId, currency, function(err, existentWallet) {
      var newWallet;
      if (!existentWallet) {
        newWallet = new Wallet({
          user_id: userId,
          currency: currency
        });
        return newWallet.save(function(err, wallet) {
          if (err) {
            return callback(err, wallet);
          }
          return wallet.generateAddress(function(e, w) {
            return Wallet.findUserWalletByCurrency(userId, currency, callback);
          });
        });
      } else {
        return callback(err, existentWallet);
      }
    });
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

  WalletSchema.statics.findByAccount = function(account, callback) {
    var id;
    if (callback == null) {
      callback = function() {};
    }
    id = account.replace("wallet_", "");
    return Wallet.findById(id, callback);
  };

  Wallet = mongoose.model("Wallet", WalletSchema);

  exports = module.exports = Wallet;

}).call(this);
