(function() {
  var MarketHelper, math;

  MarketHelper = require("../lib/market_helper");

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

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
        comment: "FLOAT x 100000000"
      },
      day_high: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      day_low: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      volume1: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      volume2: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      },
      growth_ratio: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
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
          if (order.action === "sell" && order.status === "completed") {
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
              marketStats.volume1 = math.add(marketStats.volume1, order.amount);
              marketStats.volume2 = math.select(marketStats.volume2).add(order.result_amount).add(order.fee).done();
              return marketStats.save().complete(callback);
            });
          }
        },
        calculateGrowthRatio: function(lastPrice, newPrice) {
          if (!lastPrice) {
            return 100;
          }
          return math.select(newPrice).multiply(100).divide(lastPrice).add(-100).done();
        },
        findEnabledMarket: function(currency1, currency2, callback) {
          var query, type;
          if (callback == null) {
            callback = function() {};
          }
          if (currency1 === "BTC") {
            return callback(null, true);
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
        getFloat: function(attribute) {
          return MarketHelper.fromBigint(this[attribute]);
        },
        resetIfNotToday: function() {
          var today;
          today = new Date().getDate();
          if (!this.today || (today !== this.today.getDate())) {
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
