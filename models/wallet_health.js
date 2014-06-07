(function() {
  var MarketHelper, _;

  MarketHelper = require("../lib/market_helper");

  _ = require("underscore");

  module.exports = function(sequelize, DataTypes) {
    var WalletHealth;
    WalletHealth = sequelize.define("WalletHealth", {
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
      blocks: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      connections: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      last_updated: {
        type: DataTypes.DATE
      },
      balance: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      status: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: MarketHelper.getWalletStatus("normal"),
        allowNull: false,
        comment: "normal, delayed, blocked, inactive",
        get: function() {
          return MarketHelper.getWalletStatusLiteral(this.getDataValue("status"));
        },
        set: function(status) {
          return this.setDataValue("status", MarketHelper.getWalletStatus(status));
        }
      }
    }, {
      tableName: "wallet_health",
      instanceMethods: {
        getFloat: function(attribute) {
          if (this[attribute] == null) {
            return this[attribute];
          }
          return MarketHelper.fromBigint(this[attribute]);
        }
      },
      classMethods: {
        updateFromWalletInfo: function(walletInfo, callback) {
          return WalletHealth.findOrCreate({
            currency: MarketHelper.getCurrency(walletInfo.currency)
          }).complete(function(err, wallet, created) {
            return wallet.updateAttributes(walletInfo).complete(callback);
          });
        }
      }
    });
    return WalletHealth;
  };

}).call(this);
