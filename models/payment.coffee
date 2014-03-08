module.exports = (sequelize, DataTypes) ->

  Payment = sequelize.define "Payment",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: true
      wallet_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: true
      transaction_id:
        type: DataTypes.STRING
        allowNull: true
      currency:
        type: DataTypes.STRING
        allowNull: false
      address:
        type: DataTypes.STRING
        allowNull: false
        validate:
          isValidAddress: (value)->
            pattern = /^[1-9A-Za-z]{27,34}/
            throw new Error "Invalid address."  if not pattern.test(value)
      amount:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
        validate:
          isFloat: true
          notNull: true
          min: 0.00000001
      status:
        type: DataTypes.ENUM
        values: ["pending", "processed", "canceled"]
        defaultValue: "pending"
      log:
        type: DataTypes.TEXT
      remote_ip:
        type: DataTypes.STRING

    ,
      tableName: "payments"
      classMethods:
        
        findByUserAndWallet: (userId, walletId, status, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
              status: status
          Payment.findAll(query).complete callback

        findByStatus: (status, callback)->
          query =
            where:
              status: status
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
          @log = ""  if not @log
          @log += ","  if @log.length
          try
            @log += JSON.stringify(response)
          catch e
          @save().complete callback

        cancel: (reason, callback = ()->)->
          @status = "canceled"
          reason = JSON.stringify reason
          @log = ""  if not @log
          @log += ","  if @log.length
          try
            @log += JSON.stringify(reason)
          catch e
          @save().complete (e, p)->
            callback reason, p

        errored: (reason, callback = ()->)->
          reason = JSON.stringify reason
          @log = ""  if not @log
          @log += ","  if @log.length
          try
            @log += JSON.stringify(reason)
          catch e
          @save().complete (e, p)->
            callback reason, p

  Payment