(function() {
  var MarketHelper, _;

  MarketHelper = require("../lib/market_helper");

  _ = require("underscore");

  module.exports = function(sequelize, DataTypes) {
    var Wallet;
    Wallet = sequelize.define("Wallet", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      currency: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        get: function() {
          return MarketHelper.getCurrencyLiteral(this.getDataValue("currency"));
        },
        set: function(currency) {
          return this.setDataValue("currency", MarketHelper.getCurrency(currency));
        }
      },
      address: {
        type: DataTypes.STRING(34),
        allowNull: true
      },
      balance: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("balance"));
        },
        set: function(balance) {
          return this.setDataValue("balance", MarketHelper.convertToBigint(balance));
        },
        comment: "FLOAT x 100000000"
      },
      hold_balance: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("hold_balance"));
        },
        set: function(holdBalance) {
          return this.setDataValue("hold_balance", MarketHelper.convertToBigint(holdBalance));
        },
        comment: "FLOAT x 100000000"
      },
      fee: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0.2,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("fee"));
        },
        set: function(fee) {
          return this.setDataValue("fee", MarketHelper.convertToBigint(fee));
        },
        comment: "FLOAT x 100000000"
      }
    }, {
      tableName: "wallets",
      getterMethods: {
        account: function() {
          return "wallet_" + this.id;
        },
        currency_name: function() {
          return MarketHelper.getCurrencyName(this.getDataValue("currency"));
        }
      },
      classMethods: {
        findById: function(id, callback) {
          return Wallet.find(id).complete(callback);
        },
        findByAddress: function(address, callback) {
          return Wallet.find({
            where: {
              address: address
            }
          }).complete(callback);
        },
        findUserWalletByCurrency: function(userId, currency, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return Wallet.find({
            where: {
              user_id: userId,
              currency: MarketHelper.getCurrency(currency)
            }
          }).complete(callback);
        },
        findOrCreateUserWalletByCurrency: function(userId, currency, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return Wallet.findOrCreate({
            user_id: userId,
            currency: MarketHelper.getCurrency(currency)
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
        addBalance: function(newBalance, transaction, callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (!_.isNaN(newBalance) && _.isNumber(newBalance)) {
            return this.increment({
              balance: MarketHelper.convertToBigint(newBalance)
            }, {
              transaction: transaction
            }).complete((function(_this) {
              return function(err, wl) {
                if (err) {
                  return callback("Could not add the wallet balance " + newBalance + " for " + _this.id + ": " + err);
                }
                return Wallet.find(_this.id).complete(callback);
              };
            })(this));
          } else {
            return callback("Could not add wallet balance " + newBalance + " for " + this.id);
          }
        },
        addHoldBalance: function(newBalance, transaction, callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (!_.isNaN(newBalance) && _.isNumber(newBalance)) {
            return this.increment({
              hold_balance: MarketHelper.convertToBigint(newBalance)
            }, {
              transaction: transaction
            }).complete((function(_this) {
              return function(err, wl) {
                if (err) {
                  return callback("Could not add the wallet hold balance " + newBalance + " for " + _this.id + ": " + err);
                }
                return Wallet.find(_this.id).complete(callback);
              };
            })(this));
          } else {
            return callback("Could not add wallet hold balance " + newBalance + " for " + this.id);
          }
        },
        holdBalance: function(balance, transaction, callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (!_.isNaN(balance) && _.isNumber(balance) && this.canWithdraw(balance)) {
            return this.addBalance(-balance, transaction, (function(_this) {
              return function(err) {
                if (!err) {
                  return _this.addHoldBalance(balance, transaction, callback);
                } else {
                  return callback("Could not hold wallet balance " + balance + " for " + _this.id + ", not enough funds?");
                }
              };
            })(this));
          } else {
            return callback("Could not add wallet hold balance " + balance + " for " + this.id + ", invalid balance " + balance + ".");
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
