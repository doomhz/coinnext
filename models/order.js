(function() {
  var _;

  _ = require("underscore");

  module.exports = function(sequelize, DataTypes) {
    var Order;
    Order = sequelize.define("Order", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      type: {
        type: DataTypes.ENUM,
        values: ["market", "limit"],
        allowNull: false
      },
      action: {
        type: DataTypes.ENUM,
        values: ["buy", "sell"],
        allowNull: false
      },
      buy_currency: {
        type: DataTypes.STRING,
        allowNull: false
      },
      sell_currency: {
        type: DataTypes.STRING,
        allowNull: false
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
        type: DataTypes.ENUM,
        values: ["open", "partiallyCompleted", "completed"],
        defaultValue: "open"
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
            query.where.status = ["partiallyCompleted", "open"];
          }
          if (options.status === "completed") {
            query.where.status = options.status;
          }
          if (["buy", "sell"].indexOf(options.action) > -1) {
            query.where.action = options.action;
          }
          if (options.user_id) {
            query.where.user_id = options.user_id;
          }
          if (options.action === "buy") {
            query.where.buy_currency = options.currency1;
            query.where.sell_currency = options.currency2;
          } else if (options.action === "sell") {
            query.where.buy_currency = options.currency2;
            query.where.sell_currency = options.currency1;
          } else if (!options.action) {
            currencies = [];
            if (options.currency1) {
              currencies.push(options.currency1);
            }
            if (options.currency2) {
              currencies.push(options.currency2);
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
              status: "completed",
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
