(function() {
  var _;

  _ = require("underscore");

  module.exports = function(sequelize, DataTypes) {
    var CURRENCIES, CURRENCY_NAMES, Wallet;
    CURRENCIES = ["BTC", "LTC", "PPC"];
    CURRENCY_NAMES = {
      BTC: "Bitcoin",
      LTC: "Litecoin",
      PPC: "Peercoin"
    };
    Wallet = sequelize.define("Wallet", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      currency: {
        type: DataTypes.ENUM,
        values: CURRENCIES,
        allowNull: false
      },
      address: {
        type: DataTypes.STRING,
        allowNull: false
      },
      balance: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      hold_balance: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      fee: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0.2,
        allowNull: false
      }
    }, {
      tableName: "wallets",
      getterMethods: {
        account: function() {
          return "wallet_" + this.id;
        },
        currency_name: function() {
          return CURRENCY_NAMES[this.currency];
        }
      },
      classMethods: {
        findById: function(id, callback) {
          return Wallet.find(id).complete(callback);
        },
        getCurrencies: function() {
          return CURRENCIES;
        },
        getCurrencyNames: function() {
          return CURRENCY_NAMES;
        },
        findUserWalletByCurrency: function(userId, currency, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return Wallet.find({
            where: {
              user_id: userId,
              currency: currency
            }
          }).complete(callback);
        },
        findOrCreateUserWalletByCurrency: function(userId, currency, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return Wallet.findOrCreate({
            user_id: userId,
            currency: currency
          }, {
            user_id: userId,
            currency: currency
          }).complete(callback);
        },
        findUserWallets: function(userId, callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              user_id: userId
            },
            order: [["created_at", "DESC"]]
          };
          return Wallet.findAll(query).complete(callback);
        },
        findUserWallet: function(userId, walletId, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return Wallet.find({
            where: {
              user_id: userId,
              id: walletId
            }
          }).complete(callback);
        },
        findByAccount: function(account, callback) {
          var id;
          if (callback == null) {
            callback = function() {};
          }
          id = account.replace("wallet_", "");
          return Wallet.findById(id, callback);
        },
        isValidCurrency: function(currency) {
          return CURRENCIES.indexOf(currency) > -1;
        }
      },
      instanceMethods: {
        generateAddress: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          return GLOBAL.walletsClient.send("create_account", [this.account, this.currency], (function(_this) {
            return function(err, res, body) {
              if (err) {
                console.error(err);
                return callback(err, res, body);
              }
              if (body && body.address) {
                _this.address = body.address;
                return _this.save().complete(callback);
              } else {
                console.error("Could not generate address - " + (JSON.stringify(body)));
                return callback("Invalid address");
              }
            };
          })(this));
        },
        addBalance: function(newBalance, callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (!_.isNaN(newBalance) && _.isNumber(newBalance)) {
            return this.increment({
              balance: newBalance
            }).complete((function(_this) {
              return function(err, wl) {
                if (err) {
                  console.log("Could not add the wallet balance " + newBalance + " for " + _this.id + ": " + err);
                }
                return Wallet.find(_this.id).complete(callback);
              };
            })(this));
          } else {
            console.log("Could not add wallet balance " + newBalance + " for " + this.id);
            return callback(null, this);
          }
        },
        addHoldBalance: function(newBalance, callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (!_.isNaN(newBalance) && _.isNumber(newBalance)) {
            return this.increment({
              hold_balance: newBalance
            }).complete((function(_this) {
              return function(err, wl) {
                if (err) {
                  console.log("Could not add the wallet hold balance " + newBalance + " for " + _this.id + ": " + err);
                }
                return Wallet.find(_this.id).complete(callback);
              };
            })(this));
          } else {
            console.log("Could not add wallet hold balance " + newBalance + " for " + this.id);
            return callback(null, this);
          }
        },
        holdBalance: function(balance, callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (!_.isNaN(balance) && _.isNumber(balance) && this.canWithdraw(balance)) {
            return this.addBalance(-balance, (function(_this) {
              return function(err) {
                if (!err) {
                  return _this.addHoldBalance(balance, callback);
                } else {
                  console.log("Could not hold wallet balance " + balance + " for " + _this.id + ", not enough funds?");
                  return Wallet.findById(_this.id, callback);
                }
              };
            })(this));
          } else {
            console.log("Could not add wallet hold balance " + balance + " for " + this.id);
            return callback("Invalid balance " + balance, this);
          }
        },
        canWithdraw: function(amount) {
          return parseFloat(this.balance) >= parseFloat(amount);
        }
      }
    });
    return Wallet;
  };

}).call(this);
