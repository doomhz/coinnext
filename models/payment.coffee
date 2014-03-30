MarketHelper = require "../lib/market_helper"
ipFormatter = require "ip"

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
          isFloat: true
          notNull: true
          min: 0.00000001
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("amount")
        set: (amount)->
          @setDataValue "amount", MarketHelper.convertToBigint(amount)
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

    ,
      tableName: "payments"
      classMethods:

        findById: (id, callback)->
          Payment.find(id).complete callback
        
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
      
      instanceMethods:
        
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

  Payment