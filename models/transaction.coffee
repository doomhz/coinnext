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
        defaultValue: 0
        comment: "FLOAT x 100000000"
      address:
        type: DataTypes.STRING(34)
        allowNull: false
      amount:
        type: DataTypes.BIGINT
        defaultValue: 0
        allowNull: false
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
      confirmations:
        type: DataTypes.INTEGER.UNSIGNED
        defaultValue: 0
      balance_loaded:
        type: DataTypes.BOOLEAN
        defaultValue: false

    ,
      tableName: "transactions"
      getterMethods:

        network_confirmations: ()->
          MarketHelper.getMinConfirmations @currency

      classMethods:
        
        findById: (id, callback)->
          Transaction.find(id).complete callback

        findByTxid: (txid, callback)->
          Transaction.find({where: {txid: txid}}).complete callback

        addFromWallet: (transactionData, currency, wallet, callback = ()->)->
          data =
            user_id:       (wallet.user_id if wallet)
            wallet_id:     (wallet.id if wallet)
            currency:      currency
            account:       transactionData.account
            fee:           MarketHelper.toBigint transactionData.fee  if transactionData.fee
            address:       transactionData.address
            category:      transactionData.category
            amount:        MarketHelper.toBigint transactionData.amount  if transactionData.amount
            txid:          transactionData.txid
            confirmations: transactionData.confirmations
            created_at:    new Date(transactionData.time * 1000)
          for key of data
            delete data[key]  if not data[key]?
          Transaction.findOrCreate({txid: data.txid, category: MarketHelper.getTransactionCategory(data.category)}, data).complete (err, transaction, created)->
            return callback err, transaction  if created
            transaction.updateAttributes(data).complete callback

        findPendingByUserAndWallet: (userId, walletId, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
              category: MarketHelper.getTransactionCategory "receive"
              balance_loaded: false
            order: [
              ["created_at", "DESC"]
            ]
          Transaction.findAll(query).complete callback

        findProcessedByUserAndWallet: (userId, walletId, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
            order: [
              ["created_at", "DESC"]
            ]
          query.where = sequelize.and(query.where, sequelize.or({category: MarketHelper.getTransactionCategory("receive"), balance_loaded: true}, {category: MarketHelper.getTransactionCategory("send")}))
          Transaction.findAll(query).complete callback

        findPendingByIds: (ids, callback)->
          return callback(null, [])  if ids.length is 0
          query =
            where:
              txid: ids
              balance_loaded: false
              category: MarketHelper.getTransactionCategory "receive"
            order: [
              ["created_at", "DESC"]
            ]
          Transaction.findAll(query).complete callback

        findTotalReceivedByUserAndWallet: (userId, walletId, callback)->
          query =
            where:
              user_id: userId
              wallet_id: walletId
              balance_loaded: true
              category: MarketHelper.getTransactionCategory "receive"
          Transaction.sum("amount", query).complete (err, sum = 0)->
            callback err, sum

        isValidFormat: (category)->
          !!MarketHelper.getTransactionCategory category

        setUserById: (txid, userId, callback)->
          Transaction.update({user_id: userId}, {txid: txid}).complete callback

        setUserAndWalletById: (txId, userId, walletId, callback)->
          Transaction.update({user_id: userId, wallet_id: walletId}, {txid: txId}).complete callback

        markAsLoaded: (id, mysqlTransaction, callback)->
          Transaction.update({balance_loaded: true}, {id: id}, {transaction: mysqlTransaction}).complete callback

      instanceMethods:

        getFloat: (attribute)->
          return @[attribute]  if not @[attribute]?
          MarketHelper.fromBigint @[attribute]

  Transaction