(function() {
  var MarketHelper;

  MarketHelper = require("../market_helper");

  module.exports = function(sequelize, DataTypes) {
    var EVENTS_FETCH_LIMIT, Event, VALID_EVENTS;
    EVENTS_FETCH_LIMIT = 1;
    VALID_EVENTS = [MarketHelper.getEventType("order_canceled"), MarketHelper.getEventType("order_added"), MarketHelper.getEventType("orders_match")];
    Event = sequelize.define("Event", {
      type: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        comment: "orders_match, cancel_order, order_canceled, add_order, order_added",
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
        defaultValue: MarketHelper.getEventStatus("pending"),
        comment: "pending, processed",
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
        addOrder: function(loadout, callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = {
            type: "add_order",
            loadout: loadout,
            status: "pending"
          };
          return Event.create(data).complete(callback);
        },
        addCancelOrder: function(loadout, callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = {
            type: "cancel_order",
            loadout: loadout,
            status: "pending"
          };
          return Event.create(data).complete(callback);
        },
        findNext: function(type, callback) {
          var query;
          if (type == null) {
            type = null;
          }
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              status: MarketHelper.getEventStatus("pending")
            },
            order: [["created_at", "ASC"]],
            limit: EVENTS_FETCH_LIMIT
          };
          if (type) {
            query.where.type = MarketHelper.getEventType(type);
          }
          return Event.find(query).complete(callback);
        },
        findNextValid: function(callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              status: MarketHelper.getEventStatus("pending"),
              type: VALID_EVENTS
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
