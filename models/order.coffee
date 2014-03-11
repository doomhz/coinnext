_ = require "underscore"

module.exports = (sequelize, DataTypes) ->

  Order = sequelize.define "Order",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      type:
        type: DataTypes.ENUM
        values: ["market", "limit"]
        allowNull: false
      action:
        type: DataTypes.ENUM
        values: ["buy", "sell"]
        allowNull: false
      buy_currency:
        type: DataTypes.STRING
        allowNull: false
      sell_currency:
        type: DataTypes.STRING
        allowNull: false
      amount:
        type: DataTypes.FLOAT.UNSIGNED
        defaultValue: 0
        allowNull: false
        validate:
          isFloat: true
          notNull: true
      sold_amount:
        type: DataTypes.FLOAT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
      result_amount:
        type: DataTypes.FLOAT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
      fee:
        type: DataTypes.FLOAT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
      unit_price:
        type: DataTypes.FLOAT.UNSIGNED
        defaultValue: 0
        validate:
          isFloat: true
      status:
        type: DataTypes.ENUM
        values: ["open", "partiallyCompleted", "completed"]
        defaultValue: "open"
      published:
        type: DataTypes.BOOLEAN
        defaultValue: false
      close_time:
        type: DataTypes.DATE
    ,
      tableName: "orders"
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
            query.where.status = ["partiallyCompleted", "open"]
          if options.status is "completed"
            query.where.status = options.status
          query.where.action = options.action    if ["buy", "sell"].indexOf(options.action) > -1
          query.where.user_id = options.user_id  if options.user_id
          if options.action is "buy"
            query.where.buy_currency = options.currency1
            query.where.sell_currency = options.currency2
          else if options.action is "sell"
            query.where.buy_currency = options.currency2
            query.where.sell_currency = options.currency1
          else if not options.action
            currencies = []
            currencies.push options.currency1  if options.currency1
            currencies.push options.currency2  if options.currency2
            if currencies.length > 1
              query.where.buy_currency = currencies
              query.where.sell_currency = currencies
            else if currencies.length is 1
              query.where = sequelize.and(query.where, sequelize.or({buy_currency: currencies[0]}, {sell_currency: currencies[0]}))
          else
            return callback "Wrong action", []
          Order.findAll(query).complete callback  

        findCompletedByTime: (startTime, endTime, callback)->
          query =
            where:
              status: "completed"
              close_time:
                gte: startTime
                lte: endTime
            order: [
              ["close_time", "ASC"]
            ]
          Order.findAll(query).completed callback

        isValidTradeAmount: (amount)->
          _.isNumber(amount) and not _.isNaN(amount) and amount > 0

        convertToEngineValue: (value)->
          parseFloat(value) * 100000000

        convertFromEngineValue: (value)->
          parseFloat(value) / 100000000

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