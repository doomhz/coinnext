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
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("open_price")
        set: (openPrice)->
          @setDataValue "open_price", MarketHelper.convertToBigint(openPrice)
        comment: "FLOAT x 100000000"
      close_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("close_price")
        set: (closePrice)->
          @setDataValue "close_price", MarketHelper.convertToBigint(closePrice)
        comment: "FLOAT x 100000000"
      high_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("high_price")
        set: (highPrice)->
          @setDataValue "high_price", MarketHelper.convertToBigint(highPrice)
        comment: "FLOAT x 100000000"
      low_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("low_price")
        set: (lowPrice)->
          @setDataValue "low_price", MarketHelper.convertToBigint(lowPrice)
        comment: "FLOAT x 100000000"
      volume:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("volume")
        set: (volume)->
          @setDataValue "volume", MarketHelper.convertToBigint(volume)
        comment: "FLOAT x 100000000"
      start_time:
        type: DataTypes.DATE
      end_time:
        type: DataTypes.DATE
    ,
      tableName: "trade_stats"
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
         
  TradeStats