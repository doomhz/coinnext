module.exports = (sequelize, DataTypes) ->

  PaymentLog = sequelize.define "PaymentLog",
      payment_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      log:
        type: DataTypes.TEXT
        set: (response)->
          try
            log = if typeof(response) is "string" then response else "#{response}"
            @setDataValue "log", log
          catch e
            @setDataValue "log", response
    ,
      tableName: "payment_logs"
      classMethods:

        findById: (id, callback)->
          PaymentLog.find(id).complete callback
        
        findByPaymentId: (paymentId, callback)->
          query =
            where:
              payment_id: paymentId
          PaymentLog.findAll(query).complete callback

  PaymentLog