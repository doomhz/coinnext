MarketHelper = require "../lib/market_helper"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

module.exports = (sequelize, DataTypes) ->

  MarketStats = sequelize.define "MarketStats",
      type:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        unique: true
        get: ()->
          MarketHelper.getMarketLiteral @getDataValue("type")
        set: (type)->
          @setDataValue "type", MarketHelper.getMarket(type)
      last_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("last_price")
        set: (lastPrice)->
          @setDataValue "last_price", MarketHelper.convertToBigint(lastPrice)
        comment: "FLOAT x 100000000"
      day_high:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("day_high")
        set: (dayHigh)->
          @setDataValue "day_high", MarketHelper.convertToBigint(dayHigh)
        comment: "FLOAT x 100000000"
      day_low:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("day_low")
        set: (dayLow)->
          @setDataValue "day_low", MarketHelper.convertToBigint(dayLow)
        comment: "FLOAT x 100000000"
      volume1:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("volume1")
        set: (volume1)->
          @setDataValue "volume1", MarketHelper.convertToBigint(volume1)
        comment: "FLOAT x 100000000"
      volume2:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("volume2")
        set: (volume2)->
          @setDataValue "volume2", MarketHelper.convertToBigint(volume2)
        comment: "FLOAT x 100000000"
      growth_ratio:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("growth_ratio")
        set: (growthRatio)->
          @setDataValue "growth_ratio", MarketHelper.convertToBigint(growthRatio)
        comment: "FLOAT x 100000000"
      today:
        type: DataTypes.DATE
      status:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: MarketHelper.getOrderStatus "enabled"
        allowNull: false
        comment: "enabled, disabled"
        get: ()->
          MarketHelper.getMarketStatusLiteral @getDataValue("status")
        set: (status)->
          @setDataValue "status", MarketHelper.getMarketStatus(status)
    ,
      tableName: "market_stats"
      getterMethods:

        label: ()->
          @type.substr 0, @type.indexOf("_")

      classMethods:
        
        getStats: (callback = ()->)->
          MarketStats.findAll().complete (err, marketStats)->
            stats = {}
            for stat in marketStats
              stats[stat.type] = stat
            callback err, stats
        
        trackFromOrder: (order, callback = ()->)->
          type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
          if order.action is "sell" and order.status is "completed"
            MarketStats.find({where: {type: MarketHelper.getMarket(type)}}).complete (err, marketStats)->
              marketStats.resetIfNotToday()
              marketStats.growth_ratio = MarketStats.calculateGrowthRatio marketStats.last_price, order.unit_price  if order.unit_price isnt marketStats.last_price
              marketStats.last_price = order.unit_price
              marketStats.day_high = order.unit_price  if order.unit_price > marketStats.day_high
              marketStats.day_low = order.unit_price  if order.unit_price < marketStats.day_low or marketStats.day_low is 0
              marketStats.volume1 = math.add marketStats.volume1, order.amount
              marketStats.volume2 = math.select(marketStats.volume2).add(order.result_amount).add(order.fee).done()
              marketStats.save().complete callback

        calculateGrowthRatio: (lastPrice, newPrice)->
          return 100  if not lastPrice
          math.select(newPrice).multiply(100).divide(lastPrice).add(-100).done()

        findEnabledMarket: (currency1, currency2, callback = ()->)->
          # TODO: Review when both are equal to BTC
          return callback null, true  if currency1 is "BTC"
          type = "#{currency1}_#{currency2}"
          query =
            where:
              type: MarketHelper.getMarket(type)
              status: MarketHelper.getMarketStatus("enabled")
          MarketStats.find(query).complete callback
      
        setMarketStatus: (id, status, callback = ()->)->
          MarketStats.update({status: status}, {id: id}).complete callback

      instanceMethods:
        
        resetIfNotToday: ()->
          today = new Date().getDate()
          if not @today or (today isnt @today.getDate())
            @today = new Date()
            @day_high = 0
            @day_low = 0
            @volume1 = 0
            @volume2 = 0
  
  MarketStats