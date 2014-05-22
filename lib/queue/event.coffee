MarketHelper = require "../market_helper"

module.exports = (sequelize, DataTypes) ->

  EVENTS_FETCH_LIMIT = 1

  Event = sequelize.define "Event",
      type:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        comment: "orders_match, order_canceled"
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
        defaultValue: MarketHelper.getEventStatus "unsent"
        comment: "unsent, sent"
        get: ()->
          MarketHelper.getEventStatusLiteral @getDataValue("status")
        set: (status)->
          @setDataValue "status", MarketHelper.getEventStatus(status)
    ,
      tableName: "events"
      classMethods:

        add: (type, loadout, transaction, callback = ()->)->
          Event.create({type: type, loadout: loadout}, {transaction: transaction}).complete callback

        addMatchOrders: (bulkLoadout, transaction, callback = ()->)->
          data = []
          for loadout in bulkLoadout
            data.push
              type: "orders_match"
              loadout: loadout
              status: "unsent"
          Event.bulkCreate(data, {transaction: transaction}).complete callback

        findNext: (callback = ()->)->
          query =
            where:
              status: MarketHelper.getEventStatus("unsent")
            order: [
              ["created_at", "ASC"]
            ]
            limit: EVENTS_FETCH_LIMIT
          Event.find(query).complete callback

  Event
