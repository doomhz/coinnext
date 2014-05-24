MarketHelper = require "../market_helper"

module.exports = (sequelize, DataTypes) ->

  EVENTS_FETCH_LIMIT = 1

  Event = sequelize.define "Event",
      type:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        comment: "orders_match, cancel_order, order_canceled, add_order, order_added"
        get: ()->
          MarketHelper.getEventTypeLiteral @getDataValue("type")
        set: (type)->
          @setDataValue "type", MarketHelper.getEventType(type)
      loadout:
        type: DataTypes.TEXT
        allowNull: true
        get: ()->
          JSON.parse @getDataValue("loadout")
        set: (loadout)->
          @setDataValue "loadout", JSON.stringify(loadout)
      status:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        defaultValue: MarketHelper.getEventStatus "pending"
        comment: "pending, processed"
        get: ()->
          MarketHelper.getEventStatusLiteral @getDataValue("status")
        set: (status)->
          @setDataValue "status", MarketHelper.getEventStatus(status)
    ,
      tableName: "events"
      classMethods:

        addOrder: (loadout, callback = ()->)->
          data =
            type: "add_order"
            loadout: loadout
            status: "pending"
          Event.create(data).complete callback

        addCancelOrder: (loadout, callback = ()->)->
          data =
            type: "cancel_order"
            loadout: loadout
            status: "pending"
          Event.create(data).complete callback

        findNext: (type, callback = ()->)->
          query =
            where:
              type: MarketHelper.getEventType type
              status: MarketHelper.getEventStatus "pending"
            order: [
              ["created_at", "ASC"]
            ]
            limit: EVENTS_FETCH_LIMIT
          Event.find(query).complete callback

  Event
