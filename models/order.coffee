MarketHelper = require "../lib/market_helper"
_ = require "underscore"
math = require "../lib/math"

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
        validate:
          isLimit: (value)->
            throw new Error "Market orders are disabled at the moment."  if value is MarketHelper.getOrderTypeLiteral("market")
          existentMarket: (value)->
            throw new Error "Invalid market."  if not MarketHelper.isValidMarket @action, @buy_currency, @sell_currency
      action:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        comment: "buy, sell"
        get: ()->
          MarketHelper.getOrderActionLiteral @getDataValue("action")
        set: (action)->
          @setDataValue "action", MarketHelper.getOrderAction(action)
        validate:
          buyOrSell: (value)->
            throw new Error "Please submit a valid action."  if not MarketHelper.getOrderAction @action
          sameCurrency: (value)->
            throw new Error "Please submit different currencies."  if @buy_currency is @sell_currency
      buy_currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("buy_currency")
        set: (buyCurrency)->
          @setDataValue "buy_currency", MarketHelper.getCurrency(buyCurrency)
        validate:
          existentCurrency: (value)->
            throw new Error "Please submit a valid buy currency."  if not MarketHelper.isValidCurrency @buy_currency
      sell_currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("sell_currency")
        set: (sellCurrency)->
          @setDataValue "sell_currency", MarketHelper.getCurrency(sellCurrency)
        validate:
          existentCurrency: (value)->
            throw new Error "Please submit a valid sell currency."  if not MarketHelper.isValidCurrency @sell_currency
      amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        validate:
          isInt: true
          notNull: true
          minAmount: (value)->
            throw new Error "Please submit a valid amount bigger than 0.0000001."  if not Order.isValidTradeAmount value
          minSpendAmount: (value)->
            throw new Error "Total to spend must be minimum 0.0001."  if @action is "buy" and not Order.isValidSpendAmount @amount, @action, @unit_price
        comment: "FLOAT x 100000000"
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
          minReceiveAmount: (value)->
            throw new Error "Total to receive must be minimum 0.0001."  if @action is "sell" and not Order.isValidReceiveAmount @amount, @action, @unit_price
        comment: "FLOAT x 100000000"
      fee:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isInt: true
          minFee: (value)->
            throw new Error "Minimum fee should be at least 0.00000001."  if not Order.isValidFee @amount, @action, @unit_price
        comment: "FLOAT x 100000000"
      unit_price:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        validate:
          isInt: true
          validPrice: (value)->
            throw new Error "Please submit a valid unit price amount."  if @type is "limit" and not Order.isValidUnitPriceAmount(value)
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
      in_queue:
        type: DataTypes.BOOLEAN
        defaultValue: false
        allowNull: false
      published:
        type: DataTypes.BOOLEAN
        defaultValue: false
        allowNull: false
      close_time:
        type: DataTypes.DATE
    ,
      tableName: "orders"
      paranoid: true
      getterMethods:

        inversed_action: ()->
          return "buy"  if @action is "sell"
          return "sell"  if @action is "buy"

        left_amount: ()->
          parseInt math.subtract(MarketHelper.toBignum(@amount), MarketHelper.toBignum(@matched_amount))

        left_hold_balance: ()->
          return MarketHelper.multiplyBigints @left_amount, @unit_price  if @action is "buy"
          return @left_amount  if @action is "sell"

        total: ()->
          MarketHelper.multiplyBigints @amount, @unit_price
      
      classMethods:
        
        findById: (id, callback)->
          Order.find(id).complete callback

        findByIdWithTransaction: (id, transaction, callback)->
          Order.find({where: {id: id}}, {transaction: transaction}).complete callback

        findByUserAndId: (id, userId, callback)->
          Order.find({where: {id: id, user_id: userId}}).complete callback

        findTopBid: (buyCurrency, sellCurrency, callback = ()->)->
          query = 
            limit: 1
            where:
              deleted_at: null
              action: MarketHelper.getOrderAction("buy")
              status: [MarketHelper.getOrderStatus("open"), MarketHelper.getOrderStatus("partiallyCompleted")]
              buy_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)]
              sell_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)]
            order: [
              ["unit_price", "DESC"]
            ]
          Order.find(query).complete callback

        findTopAsk: (buyCurrency, sellCurrency, callback = ()->)->
          query = 
            limit: 1
            where:
              deleted_at: null
              action: MarketHelper.getOrderAction("sell")
              status: [MarketHelper.getOrderStatus("open"), MarketHelper.getOrderStatus("partiallyCompleted")]
              buy_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)]
              sell_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)]
            order: [
              ["unit_price", "ASC"]
            ]
          Order.find(query).complete callback

        findByOptions: (options = {}, callback)->
          query =
            where: {}
            order: [
              ["created_at", "DESC"]
            ]
          query.where.deleted_at = null  if not options.include_deleted
          if options.include_logs
            query.include = [
              model: GLOBAL.db.OrderLog
              required: false
              attributes: ["matched_amount", "result_amount", "unit_price"]
              where: {}
            ]
          query.limit = options.limit  if options.limit
          if options.status is "open"
            query.where.status = [MarketHelper.getOrderStatus("partiallyCompleted"), MarketHelper.getOrderStatus("open")]
          else if options.status is "completed"
            query.where.status = MarketHelper.getOrderStatus(options.status)
          else if _.isArray options.status
            query.where.status = []
            for status in options.status
              query.where.status.push MarketHelper.getOrderStatus(status)
          query.where.action = MarketHelper.getOrderAction(options.action)  if !!MarketHelper.getOrderAction(options.action)
          query.where.user_id = options.user_id  if options.user_id?
          if options.action is "buy"
            query.where.buy_currency = MarketHelper.getCurrency options.currency1  if options.currency1?
            query.where.sell_currency = MarketHelper.getCurrency options.currency2  if options.currency2?
          else if options.action is "sell"
            query.where.buy_currency = MarketHelper.getCurrency options.currency2  if options.currency2?
            query.where.sell_currency = MarketHelper.getCurrency options.currency1  if options.currency1?
          else if not options.action
            currencies = []
            currencies.push MarketHelper.getCurrency(options.currency1)  if options.currency1?
            currencies.push MarketHelper.getCurrency(options.currency2)  if options.currency2?
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

        isValidTradeAmount: (amount)->
          _.isNumber(amount) and not _.isNaN(amount) and _.isFinite(amount) and amount >= MarketHelper.getMinTradeAmount()

        isValidUnitPriceAmount: (amount)->
          _.isNumber(amount) and not _.isNaN(amount) and _.isFinite(amount) and amount >= MarketHelper.getMinUnitPriceAmount()

        isValidFee: (amount, action, unitPrice)->
          return true  if MarketHelper.getTradeFee() is 0
          return false  if not _.isNumber(amount) or _.isNaN(amount) or not _.isFinite(amount)
          MarketHelper.calculateFee(MarketHelper.calculateResultAmount(amount, action, unitPrice)) >= MarketHelper.getMinFeeAmount()

        isValidSpendAmount: (amount, action, unitPrice)->
          return false  if not _.isNumber(amount) or _.isNaN(amount) or not _.isFinite(amount)
          MarketHelper.calculateSpendAmount(amount, action, unitPrice) >= MarketHelper.getMinSpendAmount()

        isValidReceiveAmount: (amount, action, unitPrice)->
          return false  if not _.isNumber(amount) or _.isNaN(amount) or not _.isFinite(amount)
          MarketHelper.calculateResultAmount(amount, action, unitPrice) >= MarketHelper.getMinReceiveAmount()

      instanceMethods:

        getFloat: (attribute)->
          return @[attribute]  if not @[attribute]?
          MarketHelper.fromBigint @[attribute]

        canBeCanceled: ()->
          not @in_queue and @status isnt "completed"

        publish: (callback = ()->)->
          GLOBAL.coreAPIClient.sendWithData "publish_order", @values, (err, res, body)=>
            if err
              console.error err
              return callback err, res, body
            return Order.findById body.id, callback  if body and body.id
            console.error "Could not publish the order - #{JSON.stringify(body)}"
            callback body

        cancel: (callback = ()->)->
          GLOBAL.coreAPIClient.send "cancel_order", [@id], (err, res, body)=>
            if err
              console.error err
              return callback err, res, body
            if body and body.id
              callback()
            else
              console.error "Could not cancel the order - #{JSON.stringify(body)}"
              callback "Could not cancel the order on the network"

        updateFromMatchedData: (matchedData, transaction, callback = ()->)->
          @status = matchedData.status
          @matched_amount = parseInt math.add(MarketHelper.toBignum(@matched_amount), MarketHelper.toBignum(matchedData.matched_amount))
          @result_amount = parseInt math.add(MarketHelper.toBignum(@result_amount), MarketHelper.toBignum(matchedData.result_amount))
          @fee = parseInt math.add(MarketHelper.toBignum(@fee), MarketHelper.toBignum(matchedData.fee))
          @close_time = new Date matchedData.time  if @status is "completed"
          @save({transaction: transaction}).complete callback

        calculateReceivedFromLogs: (toFloat = false)->
          resultAmount = 0
          for log in @orderLogs
            resultAmount = parseInt math.add(MarketHelper.toBignum(resultAmount), MarketHelper.toBignum(log.result_amount))
          if toFloat then MarketHelper.fromBigint(resultAmount) else resultAmount

        calculateSpentFromLogs: (toFloat = false)->
          spentAmount = 0
          if @action is "buy"
            for log in @orderLogs
              spentAmount = parseInt math.add(MarketHelper.toBignum(spentAmount), MarketHelper.toBignum(log.total))
          else
            for log in @orderLogs
              spentAmount = parseInt math.add(MarketHelper.toBignum(spentAmount), MarketHelper.toBignum(log.matched_amount))
          if toFloat then MarketHelper.fromBigint(spentAmount) else spentAmount

  Order