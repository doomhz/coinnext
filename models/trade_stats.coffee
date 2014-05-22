MarketHelper = require "../lib/market_helper"

module.exports = (sequelize, DataTypes) ->

  TradeStats = sequelize.define "TradeStats",
      type:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getMarketLiteral @getDataValue("type")
        set: (type)->
          @setDataValue "type", MarketHelper.getMarket(type)
      open_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      close_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      high_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      low_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      volume:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      exchange_volume:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      start_time:
        type: DataTypes.DATE
      end_time:
        type: DataTypes.DATE
    ,
      tableName: "trade_stats"
      timestamps: false
      classMethods:
        
        getLastStats: (type, callback = ()->)->
          type = MarketHelper.getMarket type
          halfHour = 1800000
          aDayAgo = Date.now() - 86400000 - halfHour
          query =
            where:
              type: type
              start_time:
                gt: aDayAgo
            order: [
              ["start_time", "ASC"]
            ]
          TradeStats.findAll(query).complete callback

        findLast24hByType: (type, callback)->
          type = MarketHelper.getMarket type
          halfHour = 1800000
          aDayAgo = Date.now() - 86400000 + halfHour
          query =
            where:
              type: type
              start_time:
                lt: aDayAgo
            order: [
              ["start_time", "DESC"]
            ]
          TradeStats.find(query).complete (err, tradeStats)->
            return callback err, tradeStats  if tradeStats
            query =
              where:
                type: type
              order: [
                ["start_time", "ASC"]
              ]
            TradeStats.find(query).complete (err, tradeStats)->
              callback err, tradeStats

        findByOptions: (options, callback)->
          marketId = options.marketId if options.marketId
          period = options.period if options.period
          halfHour = 1800000
          oneHour = 2 * halfHour
          sixHours = 6 * oneHour
          oneDay = 24 * oneHour
          threeDays = 3 * oneDay
          switch period
            when "6hh" then startTime = Date.now() - sixHours - halfHour
            when "1DD" then startTime = Date.now() - oneDay - halfHour
            when "3DD" then startTime = Date.now() - threeDays - halfHour
            else startTime = Date.now() - sixHours - halfHour
          query = 
            where:
              type: marketId
              start_time:
                gt: new Date(startTime)
            order: [
              ["start_time", "DESC"]
            ]
          TradeStats.findAll(query).complete callback


      instanceMethods:

        getFloat: (attribute)->
          return @[attribute]  if not @[attribute]?
          MarketHelper.fromBigint @[attribute]

  TradeStats