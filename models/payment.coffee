MarketHelper = require "../lib/market_helper"
ipFormatter = require "ip"
math = require "../lib/math"

module.exports = (sequelize, DataTypes) ->

  Payment = sequelize.define "Payment",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      wallet_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      transaction_id:
        type: DataTypes.STRING(64)
        allowNull: true
        unique: true
      currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("currency")
        set: (currency)->
          @setDataValue "currency", MarketHelper.getCurrency(currency)
      address:
        type: DataTypes.STRING(34)
        allowNull: false
        validate:
          isValidAddress: (value)->
            pattern = /^[1-9A-Za-z]{27,34}/
            throw new Error "Invalid address."  if not pattern.test(value)
      amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        validate:
          isInt: true
          notNull: true
          isBiggerThanFee: (value)->
            fee = MarketHelper.getWithdrawalFee @currency
            throw new Error "The amount is too low."  if value <= fee
        comment: "FLOAT x 100000000"
      fee:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        validate:
          isInt: true
          notNull: true
        comment: "FLOAT x 100000000"
      status:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: MarketHelper.getPaymentStatus "pending"
        comment: "pending, processed, canceled"
        get: ()->
          MarketHelper.getPaymentStatusLiteral @getDataValue("status")
        set: (status)->
          @setDataValue "status", MarketHelper.getPaymentStatus(status)
      remote_ip:
        type: DataTypes.INTEGER
        allowNull: true
        set: (ip)->
          @setDataValue "remote_ip", ipFormatter.toLong ip
        get: ()->
          ipFormatter.fromLong @getDataValue "remote_ip"
      fraud:
        type: DataTypes.BOOLEAN
        defaultValue: false

    ,
      tableName: "payments"
      classMethods:

        findById: (id, callback)->
          Payment.find(id).complete callback

        findNonProcessedById: (id, callback)->
          Payment.find({where: {id: id, status: MarketHelper.getPaymentStatus("pending")}}).complete callback
        
        findByUserAndWallet: (userId, walletId, status, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
              status: MarketHelper.getPaymentStatus(status)
          Payment.findAll(query).complete callback

        findByStatus: (status, callback)->
          query =
            where:
              status: MarketHelper.getPaymentStatus(status)
            order: [
              ["created_at", "ASC"]
            ]
          Payment.findAll(query).complete callback

        findByTransaction: (transactionId, callback)->
          query =
            where:
              transaction_id: transactionId
          Payment.find(query).complete callback

        findToProcess: (callback)->
          query =
            where:
              status: MarketHelper.getPaymentStatus "pending"
              fraud: false
            order: [
              ["created_at", "ASC"]
            ]
          Payment.findAll(query).complete callback

        findTotalPayedByUserAndWallet: (userId, walletId, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
          Payment.sum("amount", query).complete (err, totalAmount = 0)->
            return err  if err
            Payment.sum("fee", query).complete (err, totalFee = 0)->
              return err  if err
              callback err, parseInt(math.add(MarketHelper.toBignum(totalAmount), MarketHelper.toBignum(totalFee)))

        submit: (data, callback = ()->)->
          GLOBAL.coreAPIClient.sendWithData "create_payment", data, (err, res, body)=>
            if err
              console.error err
              return callback err, res, body
            return Payment.findById body.id, callback  if body and body.id
            console.error "Could not create payment - #{JSON.stringify(body)}"
            callback body
      
      instanceMethods:

        getFloat: (attribute)->
          return @[attribute]  if not @[attribute]?
          MarketHelper.fromBigint @[attribute]
        
        isProcessed: ()->
          @status is "processed"

        isCanceled: ()->
          @status is "canceled"

        isPending: ()->
          @status is "pending"

        process: (response, callback = ()->)->
          @status = "processed"
          @transaction_id = response
          GLOBAL.db.PaymentLog.create
            payment_id: @id
            log: response
          @save().complete callback

        cancel: (reason, callback = ()->)->
          @status = "canceled"
          GLOBAL.db.PaymentLog.create
            payment_id: @id
            log: reason
          @save().complete (e, p)->
            callback reason, p

        errored: (reason, callback = ()->)->
          GLOBAL.db.PaymentLog.create
            payment_id: @id
            log: reason
          @save().complete (e, p)->
            callback reason, p

        markAsFraud: (reason, callback)->
          GLOBAL.db.PaymentLog.create
            payment_id: @id
            log: JSON.stringify reason
          @fraud = true
          @save().complete (e, p)->
            callback reason, p

  Payment