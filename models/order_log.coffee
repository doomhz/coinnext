MarketHelper = require "../lib/market_helper"

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
      classMethods:

        logMatch: (matchedData, transaction, callback = ()->)->
          OrderLog.create(matchedData, {transaction: transaction}).complete callback

  OrderLog