(function() {
  module.exports = function(sequelize, DataTypes) {
    var TradeStats;
    TradeStats = sequelize.define("TradeStats", {
      type: {
        type: DataTypes.STRING,
        allowNull: false
      },
      open_price: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        allowNull: false
      },
      close_price: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        allowNull: false
      },
      high_price: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        allowNull: false
      },
      low_price: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        allowNull: false
      },
      volume: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        allowNull: false
      },
      start_time: {
        type: DataTypes.DATE
      },
      end_time: {
        type: DataTypes.DATE
      }
    }, {
      tableName: "trade_stats",
      classMethods: {
        getLastStats: function(type, callback) {
          var aDayAgo, halfHour, query;
          if (callback == null) {
            callback = function() {};
          }
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
      }
    });
    return TradeStats;
  };

}).call(this);
