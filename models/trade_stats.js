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
      exchange_volume: {
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
        },
        findLast24hByType: function(type, callback) {
          var aDayAgo, halfHour, query;
          type = MarketHelper.getMarket(type);
          halfHour = 1800000;
          aDayAgo = Date.now() - 86400000 + halfHour;
          query = {
            where: {
              type: type,
              start_time: {
                lt: aDayAgo
              }
            },
            order: [["start_time", "DESC"]]
          };
          return TradeStats.find(query).complete(function(err, tradeStats) {
            if (tradeStats) {
              return callback(err, tradeStats);
            }
            query = {
              where: {
                type: type
              },
              order: [["start_time", "ASC"]]
            };
            return TradeStats.find(query).complete(function(err, tradeStats) {
              return callback(err, tradeStats);
            });
          });
        },
        findByOptions: function(options, callback) {
          var halfHour, marketId, oneDay, oneHour, period, query, sixHours, startTime, threeDays;
          if (options.marketId) {
            marketId = options.marketId;
          }
          if (options.period) {
            period = options.period;
          }
          halfHour = 1800000;
          oneHour = 2 * halfHour;
          sixHours = 6 * oneHour;
          oneDay = 24 * oneHour;
          threeDays = 3 * oneDay;
          switch (period) {
            case "6hh":
              startTime = Date.now() - sixHours - halfHour;
              break;
            case "1DD":
              startTime = Date.now() - oneDay - halfHour;
              break;
            case "3DD":
              startTime = Date.now() - threeDays - halfHour;
              break;
            default:
              startTime = Date.now() - sixHours - halfHour;
          }
          query = {
            where: {
              type: marketId,
              start_time: {
                gt: new Date(startTime)
              }
            },
            order: [["start_time", "DESC"]]
          };
          return TradeStats.findAll(query).complete(callback);
        }
      },
      instanceMethods: {
        getFloat: function(attribute) {
          if (this[attribute] == null) {
            return this[attribute];
          }
          return MarketHelper.fromBigint(this[attribute]);
        }
      }
    });
    return TradeStats;
  };

}).call(this);
