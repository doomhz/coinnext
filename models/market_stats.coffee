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
        comment: "FLOAT x 100000000"
      day_high:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      day_low:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      volume1:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      volume2:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      growth_ratio:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
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

        exchange: ()->
          @type.substr @type.indexOf("_") + 1

      classMethods:
        
        getStats: (callback = ()->)->
          MarketStats.findAll().complete (err, marketStats)->
            stats = {}
            for stat in marketStats
              stats[stat.type] = stat
            callback err, stats
        
        trackFromOrderLog: (orderLog, callback = ()->)->
          orderLog.getOrder().complete (err, order)->
            type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
            MarketStats.find({where: {type: MarketHelper.getMarket(type)}}).complete (err, marketStats)->
              marketStats.resetIfNotToday()
              marketStats.last_price = orderLog.unit_price
              marketStats.day_high = orderLog.unit_price  if orderLog.unit_price > marketStats.day_high
              marketStats.day_low = orderLog.unit_price  if orderLog.unit_price < marketStats.day_low or marketStats.day_low is 0
              if order.action is "sell"
                # Alt currency volume traded
                marketStats.volume1 = math.add marketStats.volume1, orderLog.matched_amount
                # BTC Volume Traded
                marketStats.volume2 = math.select(marketStats.volume2).add(orderLog.result_amount).add(orderLog.fee).done()
                GLOBAL.db.TradeStats.findLast24hByType type, (err, tradeStats = {})->
                  growthRatio = MarketStats.calculateGrowthRatio tradeStats.close_price, orderLog.unit_price
                  marketStats.growth_ratio = math.round MarketHelper.toBigint(growthRatio), 0
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

        # findEnabledMarkets null, null -> all markets
        # findEnabledMarkets null, BTC -> all BTC markets
        # findEnabledMarkets LTC, BTC -> return LTC_BTC market
        findEnabledMarkets: (currency1, currency2, callback = ()->)->
          query =
            where:
              status: MarketHelper.getMarketStatus("enabled")
          if currency1 isnt null and currency2 isnt null
            query.where.type = MarketHelper.getMarket("#{currency1}_#{currency2}")
          else if currency1 is null and currency2 isnt null
            query.where.type = {}
            query.where.type.in = MarketHelper.getExchangeMarketsId(currency2)
          MarketStats.findAll(query).complete callback

      instanceMethods:

        getFloat: (attribute)->
          MarketHelper.fromBigint @[attribute]

        resetIfNotToday: ()->
          today = new Date().getDate()
          if not @today or (today isnt @today.getDate())
            @today = new Date()
            @day_high = 0
            @day_low = 0
            @volume1 = 0
            @volume2 = 0
  
  MarketStats