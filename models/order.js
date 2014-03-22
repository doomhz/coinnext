(function() {
  var MarketHelper, _;

  MarketHelper = require("../lib/market_helper");

  _ = require("underscore");

  module.exports = function(sequelize, DataTypes) {
    var Order;
    Order = sequelize.define("Order", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      type: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        comment: "market, limit",
        get: function() {
          return MarketHelper.getOrderTypeLiteral(this.getDataValue("type"));
        },
        set: function(type) {
          return this.setDataValue("type", MarketHelper.getOrderType(type));
        }
      },
      action: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        comment: "buy, sell",
        get: function() {
          return MarketHelper.getOrderActionLiteral(this.getDataValue("action"));
        },
        set: function(action) {
          return this.setDataValue("action", MarketHelper.getOrderAction(action));
        }
      },
      buy_currency: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        get: function() {
          return MarketHelper.getCurrencyLiteral(this.getDataValue("buy_currency"));
        },
        set: function(buyCurrency) {
          return this.setDataValue("buy_currency", MarketHelper.getCurrency(buyCurrency));
        }
      },
      sell_currency: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        get: function() {
          return MarketHelper.getCurrencyLiteral(this.getDataValue("sell_currency"));
        },
        set: function(sellCurrency) {
          return this.setDataValue("sell_currency", MarketHelper.getCurrency(sellCurrency));
        }
      },
      amount: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        validate: {
          isFloat: true,
          notNull: true
        }
      },
      sold_amount: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isFloat: true
        }
      },
      result_amount: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isFloat: true
        }
      },
      fee: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isFloat: true
        }
      },
      unit_price: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isFloat: true
        }
      },
      status: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: MarketHelper.getOrderStatus("open"),
        comment: "open, partiallyCompleted, completed",
        get: function() {
          return MarketHelper.getOrderStatusLiteral(this.getDataValue("status"));
        },
        set: function(status) {
          return this.setDataValue("status", MarketHelper.getOrderStatus(status));
        }
      },
      published: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
      },
      close_time: {
        type: DataTypes.DATE
      }
    }, {
      tableName: "orders",
      classMethods: {
        findById: function(id, callback) {
          return Order.find(id).complete(callback);
        },
        findByUserAndId: function(id, userId, callback) {
          return Order.find({
            where: {
              id: id,
              user_id: userId
            }
          }).complete(callback);
        },
        findByOptions: function(options, callback) {
          var currencies, query;
          if (options == null) {
            options = {};
          }
          query = {
            where: {},
            order: [["created_at", "DESC"]]
          };
          if (options.status === "open") {
            query.where.status = [MarketHelper.getOrderStatus("partiallyCompleted"), MarketHelper.getOrderStatus("open")];
          }
          if (options.status === "completed") {
            query.where.status = MarketHelper.getOrderStatus(options.status);
          }
          if (!!MarketHelper.getOrderAction(options.action)) {
            query.where.action = MarketHelper.getOrderAction(options.action);
          }
          if (options.user_id) {
            query.where.user_id = options.user_id;
          }
          if (options.action === "buy") {
            query.where.buy_currency = MarketHelper.getCurrency(options.currency1);
            query.where.sell_currency = MarketHelper.getCurrency(options.currency2);
          } else if (options.action === "sell") {
            query.where.buy_currency = MarketHelper.getCurrency(options.currency2);
            query.where.sell_currency = MarketHelper.getCurrency(options.currency1);
          } else if (!options.action) {
            currencies = [];
            if (options.currency1) {
              currencies.push(MarketHelper.getCurrency(options.currency1));
            }
            if (options.currency2) {
              currencies.push(MarketHelper.getCurrency(options.currency2));
            }
            if (currencies.length > 1) {
              query.where.buy_currency = currencies;
              query.where.sell_currency = currencies;
            } else if (currencies.length === 1) {
              query.where = sequelize.and(query.where, sequelize.or({
                buy_currency: currencies[0]
              }, {
                sell_currency: currencies[0]
              }));
            }
          } else {
            return callback("Wrong action", []);
          }
          return Order.findAll(query).complete(callback);
        },
        findCompletedByTime: function(startTime, endTime, callback) {
          var query;
          query = {
            where: {
              status: MarketHelper.getOrderStatus("completed"),
              close_time: {
                gte: startTime,
                lte: endTime
              }
            },
            order: [["close_time", "ASC"]]
          };
          return Order.findAll(query).completed(callback);
        },
        isValidTradeAmount: function(amount) {
          return _.isNumber(amount) && !_.isNaN(amount) && amount > 0;
        },
        convertToEngineValue: function(value) {
          return parseFloat(value) * 100000000;
        },
        convertFromEngineValue: function(value) {
          return parseFloat(value) / 100000000;
        }
      },
      instanceMethods: {
        publish: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          return GLOBAL.walletsClient.send("publish_order", [this.id], (function(_this) {
            return function(err, res, body) {
              if (err) {
                console.error(err);
                return callback(err, res, body);
              }
              if (body && body.published) {
                return Order.findById(_this.id, callback);
              } else {
                console.error("Could not publish the order - " + (JSON.stringify(body)));
                return callback("Could not publish the order to the network");
              }
            };
          })(this));
        },
        cancel: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          return GLOBAL.walletsClient.send("cancel_order", [this.id], (function(_this) {
            return function(err, res, body) {
              if (err) {
                console.error(err);
                return callback(err, res, body);
              }
              if (body && body.canceled) {
                return callback();
              } else {
                console.error("Could not cancel the order - " + (JSON.stringify(body)));
                return callback("Could not cancel the order on the network");
              }
            };
          })(this));
        }
      }
    });
    return Order;
  };

}).call(this);
