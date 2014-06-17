(function() {
  var MarketHelper, math;

  MarketHelper = require("../lib/market_helper");

  math = require("../lib/math");

  module.exports = function(sequelize, DataTypes) {
    var OrderLog;
    OrderLog = sequelize.define("OrderLog", {
      order_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      matched_amount: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true
        },
        comment: "FLOAT x 100000000"
      },
      result_amount: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true
        },
        comment: "FLOAT x 100000000"
      },
      fee: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true
        },
        comment: "FLOAT x 100000000"
      },
      unit_price: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true
        },
        comment: "FLOAT x 100000000"
      },
      active: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false
      },
      time: {
        type: DataTypes.DATE
      },
      status: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: MarketHelper.getOrderStatus("open"),
        allowNull: false,
        comment: "open, partiallyCompleted, completed",
        get: function() {
          return MarketHelper.getOrderStatusLiteral(this.getDataValue("status"));
        },
        set: function(status) {
          return this.setDataValue("status", MarketHelper.getOrderStatus(status));
        }
      }
    }, {
      tableName: "order_logs",
      getterMethods: {
        total: function() {
          return MarketHelper.multiplyBigints(this.matched_amount, this.unit_price);
        }
      },
      classMethods: {
        logMatch: function(matchedData, transaction, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return OrderLog.create(matchedData, {
            transaction: transaction
          }).complete(callback);
        },
        findByTimeAndAction: function(startTime, endTime, action, callback) {
          var query;
          query = {
            where: {
              time: {
                gte: new Date(startTime),
                lte: new Date(endTime)
              }
            },
            include: [
              {
                model: GLOBAL.db.Order,
                attributes: ["buy_currency", "sell_currency"],
                where: {
                  action: MarketHelper.getOrderAction(action)
                }
              }
            ],
            order: [["time", "ASC"]]
          };
          return OrderLog.findAll(query).complete(callback);
        },
        findActiveByOptions: function(options, callback) {
          var currencies, query;
          if (options == null) {
            options = {};
          }
          query = {
            where: {
              active: true
            },
            include: [
              {
                model: GLOBAL.db.Order,
                attributes: ["buy_currency", "sell_currency", "action"],
                where: {}
              }
            ],
            order: [["time", "DESC"]]
          };
          if (options.user_id) {
            query.include[0].where.user_id = options.user_id;
          }
          currencies = [];
          if (options.currency1) {
            currencies.push(MarketHelper.getCurrency(options.currency1));
          }
          if (options.currency2) {
            currencies.push(MarketHelper.getCurrency(options.currency2));
          }
          if (currencies.length > 1) {
            query.include[0].where.buy_currency = currencies;
            query.include[0].where.sell_currency = currencies;
          }
          if (options.sort_by) {
            query.order = options.sort_by;
          }
          if (options.limit) {
            query.limit = options.limit;
          }
          return OrderLog.findAll(query).complete(callback);
        },
        getNumberOfTrades: function(options, callback) {
          if (options == null) {
            options = {};
          }
          return OrderLog.count().complete(callback);
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
    return OrderLog;
  };

}).call(this);
