MarketHelper = require "../lib/market_helper"
_ = require "underscore"

module.exports = (sequelize, DataTypes) ->

  WalletHealth = sequelize.define "WalletHealth",
      currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("currency")
        set: (currency)->
          @setDataValue "currency", MarketHelper.getCurrency(currency)
      blocks:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: 0
        allowNull: false
      connections:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: 0
        allowNull: false
      last_updated:
        type: DataTypes.DATE
      balance:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      status:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: MarketHelper.getWalletStatus "normal"
        allowNull: false
        comment: "normal, delayed, blocked, inactive"
        get: ()->
          MarketHelper.getWalletStatusLiteral @getDataValue("status")
        set: (status)->
          @setDataValue "status", MarketHelper.getWalletStatus(status)
    ,
      tableName: "wallet_health"
      instanceMethods:

        getFloat: (attribute)->
          return @[attribute]  if not @[attribute]?
          MarketHelper.fromBigint @[attribute]

      classMethods:

        updateFromWalletInfo: (walletInfo, callback)->
          WalletHealth.findOrCreate({currency: MarketHelper.getCurrency(walletInfo.currency)}).complete (err, wallet, created)->
            wallet.updateAttributes(walletInfo).complete callback

  WalletHealth

