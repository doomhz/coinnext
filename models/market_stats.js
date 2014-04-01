(function() {
  var MarketHelper;

  MarketHelper = require("../lib/market_helper");

  module.exports = function(sequelize, DataTypes) {
    var MarketStats;
    MarketStats = sequelize.define("MarketStats", {
      type: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        unique: true,
        get: function() {
          return MarketHelper.getMarketLiteral(this.getDataValue("type"));
        },
        set: function(type) {
          return this.setDataValue("type", MarketHelper.getMarket(type));
        }
      },
      last_price: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("last_price"));
        },
        set: function(lastPrice) {
          return this.setDataValue("last_price", MarketHelper.convertToBigint(lastPrice));
        },
        comment: "FLOAT x 100000000"
      },
      day_high: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("day_high"));
        },
        set: function(dayHigh) {
          return this.setDataValue("day_high", MarketHelper.convertToBigint(dayHigh));
        },
        comment: "FLOAT x 100000000"
      },
      day_low: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("day_low"));
        },
        set: function(dayLow) {
          return this.setDataValue("day_low", MarketHelper.convertToBigint(dayLow));
        },
        comment: "FLOAT x 100000000"
      },
      volume1: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("volume1"));
        },
        set: function(volume1) {
          return this.setDataValue("volume1", MarketHelper.convertToBigint(volume1));
        },
        comment: "FLOAT x 100000000"
      },
      volume2: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("volume2"));
        },
        set: function(volume2) {
          return this.setDataValue("volume2", MarketHelper.convertToBigint(volume2));
        },
        comment: "FLOAT x 100000000"
      },
      growth_ratio: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        get: function() {
          return MarketHelper.convertFromBigint(this.getDataValue("growth_ratio"));
        },
        set: function(growthRatio) {
          return this.setDataValue("growth_ratio", MarketHelper.convertToBigint(growthRatio));
        },
        comment: "FLOAT x 100000000"
      },
      today: {
        type: DataTypes.DATE
      },
      status: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: MarketHelper.getOrderStatus("enabled"),
        allowNull: false,
        comment: "enabled, disabled",
        get: function() {
          return MarketHelper.getMarketStatusLiteral(this.getDataValue("status"));
        },
        set: function(status) {
          return this.setDataValue("status", MarketHelper.getMarketStatus(status));
        }
      }
    }, {
      tableName: "market_stats",
      getterMethods: {
        label: function() {
          return this.type.substr(0, this.type.indexOf("_"));
        }
      },
      classMethods: {
        getStats: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          return MarketStats.findAll().complete(function(err, marketStats) {
            var stat, stats, _i, _len;
            stats = {};
            for (_i = 0, _len = marketStats.length; _i < _len; _i++) {
              stat = marketStats[_i];
              stats[stat.type] = stat;
            }
            return callback(err, stats);
          });
        },
        trackFromOrder: function(order, callback) {
          var type;
          if (callback == null) {
            callback = function() {};
          }
          type = order.action === "buy" ? "" + order.buy_currency + "_" + order.sell_currency : "" + order.sell_currency + "_" + order.buy_currency;
          if (order.action === "sell") {
            return MarketStats.find({
              where: {
                type: MarketHelper.getMarket(type)
              }
            }).complete(function(err, marketStats) {
              marketStats.resetIfNotToday();
              if (order.unit_price !== marketStats.last_price) {
                marketStats.growth_ratio = MarketStats.calculateGrowthRatio(marketStats.last_price, order.unit_price);
              }
              marketStats.last_price = order.unit_price;
              if (order.unit_price > marketStats.day_high) {
                marketStats.day_high = order.unit_price;
              }
              if (order.unit_price < marketStats.day_low || marketStats.day_low === 0) {
                marketStats.day_low = order.unit_price;
              }
              marketStats.volume1 += order.amount;
              marketStats.volume2 += order.result_amount;
              return marketStats.save().complete(callback);
            });
          }
        },
        calculateGrowthRatio: function(lastPrice, newPrice) {
          return parseFloat(newPrice * 100 / lastPrice - 100);
        },
        findEnabledMarket: function(currency1, currency2, callback) {
          var query, type;
          if (callback == null) {
            callback = function() {};
          }
          type = "" + currency1 + "_" + currency2;
          query = {
            where: {
              type: MarketHelper.getMarket(type),
              status: MarketHelper.getMarketStatus("enabled")
            }
          };
          return MarketStats.find(query).complete(callback);
        },
        setMarketStatus: function(id, status, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return MarketStats.update({
            status: status
          }, {
            id: id
          }).complete(callback);
        }
      },
      instanceMethods: {
        resetIfNotToday: function() {
          var today;
          today = new Date().getDate();
          if (today !== this.today.getDate()) {
            this.today = new Date();
            this.day_high = 0;
            this.day_low = 0;
            this.volume1 = 0;
            return this.volume2 = 0;
          }
        }
      }
    });
    return MarketStats;
  };

}).call(this);
