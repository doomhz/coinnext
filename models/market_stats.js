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
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      day_high: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      day_low: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      volume1: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      volume2: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      growth_ratio: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false
      },
      today: {
        type: DataTypes.DATE
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
