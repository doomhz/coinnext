MarketHelper = require "../lib/market_helper"
math = require "../lib/math"
_ = require "underscore"

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
      yesterday_price:
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
      top_bid:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      top_ask:
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
          @type.substr 0, @type.indexOf("_")  if @type

        exchange: ()->
          @type.substr @type.indexOf("_") + 1  if @type

      classMethods:
        
        getStats: (callback = ()->)->
          query =
            where:
              status:
                ne: MarketHelper.getMarketStatus "removed"
          MarketStats.findAll(query).complete (err, marketStats)->
            marketStats = _.sortBy marketStats, (s)->
              s.type
            stats = {}
            for stat in marketStats
              stats[stat.type] = stat
            callback err, stats
        
        trackFromNewOrder: (order, callback = ()->)->
          type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
          MarketStats.find({where: {type: MarketHelper.getMarket(type)}}).complete (err, marketStats)->
            if order.action is "buy"
              marketStats.top_bid = order.unit_price  if order.unit_price > marketStats.top_bid
            if order.action is "sell"
              marketStats.top_ask = order.unit_price  if order.unit_price < marketStats.top_ask or marketStats.top_ask is 0
            marketStats.save().complete callback

        trackFromCancelledOrder: (order, callback = ()->)->
          type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
          MarketStats.find({where: {type: MarketHelper.getMarket(type)}}).complete (err, marketStats)->
            GLOBAL.db.Order.findTopBid order.buy_currency, order.sell_currency, (err1, topBidOrder)->
              GLOBAL.db.Order.findTopAsk order.buy_currency, order.sell_currency, (err2, topAskOrder)->
                marketStats.top_bid = if topBidOrder then topBidOrder.unit_price else 0
                marketStats.top_ask = if topAskOrder then topAskOrder.unit_price else 0
                marketStats.save().complete callback

        trackFromMatchedOrder: (orderToMatch, matchingOrder, callback = ()->)->
          type = if orderToMatch.action is "buy" then "#{orderToMatch.buy_currency}_#{orderToMatch.sell_currency}" else "#{orderToMatch.sell_currency}_#{orderToMatch.buy_currency}"
          MarketStats.find({where: {type: MarketHelper.getMarket(type)}}).complete (err, marketStats)->
            GLOBAL.db.Order.findTopBid orderToMatch.buy_currency, orderToMatch.sell_currency, (err1, topBidOrder)->
              GLOBAL.db.Order.findTopAsk orderToMatch.buy_currency, orderToMatch.sell_currency, (err2, topAskOrder)->
                marketStats.top_bid = if topBidOrder then topBidOrder.unit_price else 0
                marketStats.top_ask = if topAskOrder then topAskOrder.unit_price else 0
                marketStats.save().complete callback

        trackFromOrderLog: (orderLog, callback = ()->)->
          orderLog.getOrder().complete (err, order)->
            type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
            MarketStats.find({where: {type: MarketHelper.getMarket(type)}}).complete (err, marketStats)->
              marketStats.resetIfNotToday()
              marketStats.last_price = orderLog.unit_price
              marketStats.day_high = orderLog.unit_price  if orderLog.unit_price > marketStats.day_high
              marketStats.day_low = orderLog.unit_price  if orderLog.unit_price < marketStats.day_low or marketStats.day_low is 0
              if order.action is "buy"
                marketStats.save().complete callback
              if order.action is "sell"
                # Alt currency volume traded
                marketStats.volume1 = parseInt math.add(MarketHelper.toBignum(marketStats.volume1), MarketHelper.toBignum(orderLog.matched_amount))
                # BTC Volume Traded
                marketStats.volume2 = parseInt math.select(MarketHelper.toBignum(marketStats.volume2)).add(MarketHelper.toBignum(orderLog.result_amount)).add(MarketHelper.toBignum(orderLog.fee)).done()
                GLOBAL.db.TradeStats.findLast24hByType type, (err, tradeStats = {})->
                  growthRatio = MarketStats.calculateGrowthRatio tradeStats.close_price, orderLog.unit_price
                  marketStats.growth_ratio = math.round MarketHelper.toBigint(growthRatio), 0
                  marketStats.save().complete callback

        calculateGrowthRatio: (lastPrice, newPrice)->
          return 100  if not lastPrice
          parseFloat math.select(MarketHelper.toBignum(newPrice)).multiply(MarketHelper.toBignum(100)).divide(MarketHelper.toBignum(lastPrice)).subtract(MarketHelper.toBignum(100)).done()

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

        # findMarkets null, null -> all markets
        # findMarkets null, BTC -> all BTC markets
        # findMarkets LTC, BTC -> return LTC_BTC market
        findMarkets: (currency1, currency2, callback = ()->)->
          query =
            where:
              status:
                ne: MarketHelper.getMarketStatus "removed"
          if currency1 isnt null and currency2 isnt null
            query.where.type = MarketHelper.getMarket("#{currency1}_#{currency2}")
          else if currency1 is null and currency2 isnt null
            query.where.type = {}
            query.where.type.in = MarketHelper.getExchangeMarketsId(currency2)
          MarketStats.findAll(query).complete callback

        findRemovedCurrencies: (callback = ()->)->
          query =
            where:
              status: MarketHelper.getMarketStatus "removed"
          MarketStats.findAll(query).complete (err, removedMarkets = [])->
            removedCurrencies = []
            for market in removedMarkets
              removedCurrencies.push market.label
            callback err, removedCurrencies

      instanceMethods:

        getFloat: (attribute)->
          MarketHelper.fromBigint @[attribute]

        resetIfNotToday: ()->
          today = new Date().getDate()
          if not @today or (today isnt @today.getDate())
            @today = new Date()
            @yesterday_price = @last_price
            @day_high = 0
            @day_low = 0
            @top_bid = 0
            @top_ask = 0
            @volume1 = 0
            @volume2 = 0
  
  MarketStats