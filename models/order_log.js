(function() {
  var MarketHelper;

  MarketHelper = require("../lib/market_helper");

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
      classMethods: {
        logMatch: function(matchedData, transaction, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return OrderLog.create(matchedData, {
            transaction: transaction
          }).complete(callback);
        }
      }
    });
    return OrderLog;
  };

}).call(this);
