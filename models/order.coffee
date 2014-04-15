MarketHelper = require "../lib/market_helper"
_ = require "underscore"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

module.exports = (sequelize, DataTypes) ->

  Order = sequelize.define "Order",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      type:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        comment: "market, limit"
        get: ()->
          MarketHelper.getOrderTypeLiteral @getDataValue("type")
        set: (type)->
          @setDataValue "type", MarketHelper.getOrderType(type)
      action:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        comment: "buy, sell"
        get: ()->
          MarketHelper.getOrderActionLiteral @getDataValue("action")
        set: (action)->
          @setDataValue "action", MarketHelper.getOrderAction(action)
      buy_currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("buy_currency")
        set: (buyCurrency)->
          @setDataValue "buy_currency", MarketHelper.getCurrency(buyCurrency)
      sell_currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("sell_currency")
        set: (sellCurrency)->
          @setDataValue "sell_currency", MarketHelper.getCurrency(sellCurrency)
      amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        validate:
          isFloat: true
          notNull: true
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("amount")
        set: (amount)->
          @setDataValue "amount", MarketHelper.convertToBigint(amount)
        comment: "FLOAT x 100000000"
      matched_amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("matched_amount")
        set: (matchedAmount)->
          @setDataValue "matched_amount", MarketHelper.convertToBigint(matchedAmount)
        comment: "FLOAT x 100000000"
      result_amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("result_amount")
        set: (resultAmount)->
          @setDataValue "result_amount", MarketHelper.convertToBigint(resultAmount)
        comment: "FLOAT x 100000000"
      fee:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("fee")
        set: (fee)->
          @setDataValue "fee", MarketHelper.convertToBigint(fee)
        comment: "FLOAT x 100000000"
      unit_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("unit_price")
        set: (unitPrice)->
          @setDataValue "unit_price", MarketHelper.convertToBigint(unitPrice)
        comment: "FLOAT x 100000000"
      status:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: MarketHelper.getOrderStatus "open"
        allowNull: false
        comment: "open, partiallyCompleted, completed"
        get: ()->
          MarketHelper.getOrderStatusLiteral @getDataValue("status")
        set: (status)->
          @setDataValue "status", MarketHelper.getOrderStatus(status)
      published:
        type: DataTypes.BOOLEAN
        defaultValue: false
        allowNull: false
      close_time:
        type: DataTypes.DATE
    ,
      tableName: "orders"
      getterMethods:

        inversed_action: ()->
          return "buy"  if @action is "sell"
          return "sell"  if @action is "buy"

        left_amount: ()->
          math.add(@amount, -@matched_amount)

        left_hold_balance: ()->
          return math.multiply @left_amount, @unit_price  if @action is "buy"
          return @left_amount  if @action is "sell"
      
      classMethods:
        
        findById: (id, callback)->
          Order.find(id).complete callback

        findByUserAndId: (id, userId, callback)->
          Order.find({where: {id: id, user_id: userId}}).complete callback
      
        findByOptions: (options = {}, callback)->
          query =
            where: {}
            order: [
              ["created_at", "DESC"]
            ]
          if options.status is "open"
            query.where.status = [MarketHelper.getOrderStatus("partiallyCompleted"), MarketHelper.getOrderStatus("open")]
          if options.status is "completed"
            query.where.status = MarketHelper.getOrderStatus(options.status)
          query.where.action = MarketHelper.getOrderAction(options.action)    if !!MarketHelper.getOrderAction(options.action)
          query.where.user_id = options.user_id  if options.user_id
          if options.action is "buy"
            query.where.buy_currency = MarketHelper.getCurrency options.currency1
            query.where.sell_currency = MarketHelper.getCurrency options.currency2
          else if options.action is "sell"
            query.where.buy_currency = MarketHelper.getCurrency options.currency2
            query.where.sell_currency = MarketHelper.getCurrency options.currency1
          else if not options.action
            currencies = []
            currencies.push MarketHelper.getCurrency(options.currency1)  if options.currency1
            currencies.push MarketHelper.getCurrency(options.currency2)  if options.currency2
            if currencies.length > 1
              query.where.buy_currency = currencies
              query.where.sell_currency = currencies
            else if currencies.length is 1
              query.where = sequelize.and(query.where, sequelize.or({buy_currency: currencies[0]}, {sell_currency: currencies[0]}))
          else
            return callback "Wrong action", []
          query.where.published = !!options.published  if options.published?
          query.order = options.sort_by  if options.sort_by
          Order.findAll(query).complete callback  

        findCompletedByTimeAndAction: (startTime, endTime, action, callback)->
          query =
            where:
              status: MarketHelper.getOrderStatus("completed")
              action: MarketHelper.getOrderAction action
              close_time:
                gte: new Date(startTime)
                lte: new Date(endTime)
            order: [
              ["close_time", "ASC"]
            ]
          Order.findAll(query).complete callback

        isValidTradeAmount: (amount)->
          _.isNumber(amount) and not _.isNaN(amount) and amount > 0

      instanceMethods:
        
        publish: (callback = ()->)->
          GLOBAL.walletsClient.send "publish_order", [@id], (err, res, body)=>
            if err
              console.error err
              return callback err, res, body
            if body and body.published
              Order.findById @id, callback
            else
              console.error "Could not publish the order - #{JSON.stringify(body)}"
              callback "Could not publish the order to the network"

        cancel: (callback = ()->)->
          GLOBAL.walletsClient.send "cancel_order", [@id], (err, res, body)=>
            if err
              console.error err
              return callback err, res, body
            if body and body.canceled
              callback()
            else
              console.error "Could not cancel the order - #{JSON.stringify(body)}"
              callback "Could not cancel the order on the network"

  Order