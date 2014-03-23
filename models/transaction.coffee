MarketHelper = require "../lib/market_helper"

module.exports = (sequelize, DataTypes) ->

  Transaction = sequelize.define "Transaction",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: true
      wallet_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: true
      currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("currency")
        set: (currency)->
          @setDataValue "currency", MarketHelper.getCurrency(currency)
      account:
        type: DataTypes.STRING(50)
      fee:
        type: DataTypes.BIGINT.UNSIGNED
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("fee")
        set: (fee)->
          @setDataValue "fee", MarketHelper.convertToBigint(fee)
        comment: "FLOAT x 100000000"
      address:
        type: DataTypes.STRING(34)
        allowNull: false
      amount:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        get: ()->
          MarketHelper.convertFromBigint @getDataValue("amount")
        set: (amount)->
          @setDataValue "amount", MarketHelper.convertToBigint(amount)
        comment: "FLOAT x 100000000"
      category:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        comment: "send, receive"
        get: ()->
          MarketHelper.getTransactionCategoryLiteral @getDataValue("category")
        set: (category)->
          @setDataValue "category", MarketHelper.getTransactionCategory(category)
      txid:
        type: DataTypes.STRING(64)
        allowNull: false
        unique: true
      confirmations:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: 0
      balance_loaded:
        type: DataTypes.BOOLEAN
        defaultValue: false

    ,
      tableName: "transactions"
      classMethods:
        
        findById: (id, callback)->
          Transaction.find(id).complete callback

        addFromWallet: (transactionData, currency, wallet, callback = ()->)->
          details = transactionData.details[0] or {}
          data =
            user_id:       (wallet.user_id if wallet)
            wallet_id:     (wallet.id if wallet)
            currency:      currency
            account:       details.account
            fee:           details.fee
            address:       details.address
            category:      details.category
            amount:        transactionData.amount
            txid:          transactionData.txid
            confirmations: transactionData.confirmations
            created_at:       new Date(transactionData.time * 1000)
          for key of data
            delete data[key]  if not data[key] and data[key] isnt 0
          Transaction.findOrCreate({txid: data.txid}, data).complete (err, transaction, created)->
            return callback err, transaction  if created
            transaction.updateAttributes(data).complete callback

        findPendingByUserAndWallet: (userId, walletId, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
              confirmations:
                lt: MarketHelper.getTransactionMinConf()
            order: [
              ["created_at", "DESC"]
            ]
          Transaction.findAll(query).complete callback

        findProcessedByUserAndWallet: (userId, walletId, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
              confirmations:
                gte: MarketHelper.getTransactionMinConf()
            order: [
              ["created_at", "DESC"]
            ]
          Transaction.findAll(query).complete callback

        findPendingByIds: (ids, callback)->
          return callback(null, [])  if ids.length is 0
          query =
            where:
              txid: ids
              confirmations:
                lt: MarketHelper.getTransactionMinConf()
            order: [
              ["created_at", "DESC"]
            ]
          Transaction.findAll(query).complete callback

        findByTxid: (txid, callback)->
          Transaction.find({where: {txid: txid}}).complete callback

        isValidFormat: (category)->
          !!MarketHelper.getTransactionCategory category

        setUserById: (txid, userId, callback)->
          Transaction.update({user_id: userId}, {txid: txid}).complete callback

        setUserAndWalletById: (txId, userId, walletId, callback)->
          Transaction.update({user_id: userId, wallet_id: walletId}, {txid: txId}).complete callback

        markAsLoaded: (id, callback)->
          Transaction.update({balance_loaded: true}, {id: id}).complete callback

  Transaction