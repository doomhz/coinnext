(function() {
  var MarketHelper;

  MarketHelper = require("../lib/market_helper");

  module.exports = function(sequelize, DataTypes) {
    var TradeStats;
    TradeStats = sequelize.define("TradeStats", {
      type: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        get: function() {
          return MarketHelper.getMarketLiteral(this.getDataValue("type"));
        },
        set: function(type) {
          return this.setDataValue("type", MarketHelper.getMarket(type));
        }
      },
      open_price: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      close_price: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      high_price: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      low_price: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      volume: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      start_time: {
        type: DataTypes.DATE
      },
      end_time: {
        type: DataTypes.DATE
      }
    }, {
      tableName: "trade_stats",
      timestamps: false,
      classMethods: {
        getLastStats: function(type, callback) {
          var aDayAgo, halfHour, query;
          if (callback == null) {
            callback = function() {};
          }
          type = MarketHelper.getMarket(type);
          halfHour = 1800000;
          aDayAgo = Date.now() - 86400000 - halfHour;
          query = {
            where: {
              type: type,
              start_time: {
                gt: aDayAgo
              }
            },
            order: [["start_time", "ASC"]]
          };
          return TradeStats.findAll(query).complete(callback);
        }
      },
      instanceMethods: {
        getFloat: function(attribute) {
          return MarketHelper.fromBigint(this[attribute]);
        }
      }
    });
    return TradeStats;
  };

}).call(this);
