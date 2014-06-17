MarketHelper = require "../lib/market_helper"
math = require "../lib/math"

module.exports = (sequelize, DataTypes) ->

  OrderLog = sequelize.define "OrderLog",
      order_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      matched_amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isInt: true
        comment: "FLOAT x 100000000"
      result_amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isInt: true
        comment: "FLOAT x 100000000"
      fee:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isInt: true
        comment: "FLOAT x 100000000"
      unit_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isInt: true
        comment: "FLOAT x 100000000"
      active:
        type: DataTypes.BOOLEAN
        defaultValue: false
        allowNull: false
      time:
        type: DataTypes.DATE
      status:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: MarketHelper.getOrderStatus "open"
        allowNull: false
        comment: "open, partiallyCompleted, completed"
        get: ()->
          MarketHelper.getOrderStatusLiteral @getDataValue("status")
        set: (status)->
          @setDataValue "status", MarketHelper.getOrderStatus(status)
    ,
      tableName: "order_logs"
      getterMethods:

        total: ()->
          MarketHelper.multiplyBigints @matched_amount, @unit_price

      classMethods:

        logMatch: (matchedData, transaction, callback = ()->)->
          OrderLog.create(matchedData, {transaction: transaction}).complete callback

        findByTimeAndAction: (startTime, endTime, action, callback)->
          query =
            where:
              time:
                gte: new Date(startTime)
                lte: new Date(endTime)
            include: [
              model: GLOBAL.db.Order
              attributes: ["buy_currency", "sell_currency"]
              where:
                action: MarketHelper.getOrderAction action
            ]
            order: [
              ["time", "ASC"]
            ]
          OrderLog.findAll(query).complete callback

        findActiveByOptions: (options = {}, callback)->
          query =
            where:
              active: true
            include: [
              model: GLOBAL.db.Order
              attributes: ["buy_currency", "sell_currency", "action"]
              where: {}
            ]
            order: [
              ["time", "DESC"]
            ]
          query.include[0].where.user_id = options.user_id  if options.user_id
          currencies = []
          currencies.push MarketHelper.getCurrency(options.currency1)  if options.currency1
          currencies.push MarketHelper.getCurrency(options.currency2)  if options.currency2
          if currencies.length > 1
            query.include[0].where.buy_currency = currencies
            query.include[0].where.sell_currency = currencies
          query.order = options.sort_by  if options.sort_by
          query.limit = options.limit  if options.limit
          OrderLog.findAll(query).complete callback

        getNumberOfTrades: (options = {}, callback)->
          OrderLog.count().complete callback

      instanceMethods:

        getFloat: (attribute)->
          return @[attribute]  if not @[attribute]?
          MarketHelper.fromBigint @[attribute]

  OrderLog