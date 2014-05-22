(function() {
  var MarketHelper;

  MarketHelper = require("../market_helper");

  module.exports = function(sequelize, DataTypes) {
    var EVENTS_FETCH_LIMIT, Event;
    EVENTS_FETCH_LIMIT = 1;
    Event = sequelize.define("Event", {
      type: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        comment: "orders_match, order_canceled",
        get: function() {
          return MarketHelper.getEventTypeLiteral(this.getDataValue("type"));
        },
        set: function(type) {
          return this.setDataValue("type", MarketHelper.getEventType(type));
        }
      },
      loadout: {
        type: DataTypes.TEXT,
        allowNull: true,
        get: function() {
          return JSON.parse(this.getDataValue("loadout"));
        },
        set: function(loadout) {
          return this.setDataValue("loadout", JSON.stringify(loadout));
        }
      },
      status: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        defaultValue: MarketHelper.getEventStatus("unsent"),
        comment: "unsent, sent",
        get: function() {
          return MarketHelper.getEventStatusLiteral(this.getDataValue("status"));
        },
        set: function(status) {
          return this.setDataValue("status", MarketHelper.getEventStatus(status));
        }
      }
    }, {
      tableName: "events",
      classMethods: {
        add: function(type, loadout, transaction, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return Event.create({
            type: type,
            loadout: loadout
          }, {
            transaction: transaction
          }).complete(callback);
        },
        addMatchOrders: function(bulkLoadout, transaction, callback) {
          var data, loadout, _i, _len;
          if (callback == null) {
            callback = function() {};
          }
          data = [];
          for (_i = 0, _len = bulkLoadout.length; _i < _len; _i++) {
            loadout = bulkLoadout[_i];
            data.push({
              type: "orders_match",
              loadout: loadout,
              status: "unsent"
            });
          }
          return Event.bulkCreate(data, {
            transaction: transaction
          }).complete(callback);
        },
        findNext: function(callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              status: MarketHelper.getEventStatus("unsent")
            },
            order: [["created_at", "ASC"]],
            limit: EVENTS_FETCH_LIMIT
          };
          return Event.find(query).complete(callback);
        }
      }
    });
    return Event;
  };

}).call(this);
