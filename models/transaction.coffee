module.exports = (sequelize, DataTypes) ->

  ACCEPTED_CATEGORIES = ["send", "receive"]

  Transaction = sequelize.define "Transaction",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: true
      wallet_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: true
      currency:
        type: DataTypes.STRING
        allowNull: false
      account:
        type: DataTypes.STRING
      fee:
        type: DataTypes.STRING
      address:
        type: DataTypes.STRING
        allowNull: false
      amount:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      category:
        type: DataTypes.STRING
        allowNull: false
      txid:
        type: DataTypes.STRING
        allowNull: false
        unique: true
      confirmations:
        type: DataTypes.INTEGER
        defaultValue: 0
      balance_loaded:
        type: DataTypes.BOOLEAN
        defaultValue: false

    ,
      underscored: true
      tableName: "transactions"
      classMethods:
        
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
                lt: 3
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
                gt: 2
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
                lt: 3
            order: [
              ["created_at", "DESC"]
            ]
          Transaction.findAll(query).complete callback

        isValidFormat: (category)->
          ACCEPTED_CATEGORIES.indexOf(category) > -1

        setUserById: (txId, userId, callback)->
          Transaction.update({user_id: userId}, {txid: txId}).complete callback

        setUserAndWalletById: (txId, userId, walletId, callback)->
          Transaction.update({user_id: userId, wallet_id: walletId}, {txid: txId}).complete callback

        markAsLoaded: (id, callback)->
          Transaction.update({balance_loaded: true}, {id: id}).complete callback

  Transaction