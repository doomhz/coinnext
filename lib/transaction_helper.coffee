Wallet = GLOBAL.db.Wallet
Transaction = GLOBAL.db.Transaction
Payment = GLOBAL.db.Payment
MarketStats = GLOBAL.db.MarketStats
JsonRenderer = require "./json_renderer"
ClientSocket = require "./client_socket"
usersSocket = new ClientSocket
  namespace: "users"
  redis: GLOBAL.appConfig().redis
math = require("mathjs")
  number: "bignumber"
  decimals: 8

TransactionHelper =

  paymentsProcessedUserIds: []

  pushToUser: (data)->
    usersSocket.send data

  createPayment: (data, callback)->
    Wallet.findUserWallet data.user_id, data.wallet_id, (err, wallet)->
      return callback "Wrong wallet."  if not wallet
      return callback "You don't have enough funds."  if not wallet.canWithdraw data.amount, true
      return callback "You can't withdraw to the same address."  if data.address is wallet.address
      data.currency = wallet.currency
      GLOBAL.db.sequelize.transaction (transaction)->
        Payment.create(data, {transaction: transaction}).complete (err, pm)->
          if err
            console.error err
            return transaction.rollback().success ()->
              return callback JsonRenderer.error err
          totalWithdrawalAmount = math.add(wallet.withdrawal_fee, pm.amount)
          wallet.addBalance -totalWithdrawalAmount, transaction, (err, wallet)->
            if err
              console.error err
              return transaction.rollback().success ()->
                return callback JsonRenderer.error err
            transaction.commit().success ()->
              callback null, pm
              TransactionHelper.pushToUser
                type: "wallet-balance-changed"
                user_id: wallet.user_id
                eventData: JsonRenderer.wallet wallet
            transaction.done (err)->
              callback JsonRenderer.error err  if err

  processPayment: (payment, callback)->
    MarketStats.findEnabledMarket payment.currency, "BTC", (err, market)->
      return callback null, "#{new Date()} - Will not process payment #{payment.id}, the market for #{payment.currency} is disabled."  if not market
      Wallet.findById payment.wallet_id, (err, wallet)->
        return callback null, "#{payment.id} - wallet #{payment.wallet_id} not found"  if not wallet
        return callback null, "#{payment.id} - user already had a processed payment"  if TransactionHelper.paymentsProcessedUserIds.indexOf(wallet.user_id) > -1
        #return callback null, "#{payment.id} - not processed - no funds"  if not wallet.canWithdraw payment.amount, true
        TransactionHelper.pay payment, (err, p)->
          TransactionHelper.paymentsProcessedUserIds.push wallet.user_id
          Transaction.setUserById p.transaction_id, p.user_id, ()->
            callback null, "#{payment.id} - processed"
            usersSocket.send
              type: "payment-processed"
              user_id: payment.user_id
              eventData: JsonRenderer.payment p

  cancelPayment: (payment, callback)->
    Wallet.findUserWalletByCurrency payment.user_id, payment.currency, (err, wallet)->
      return callback err  if err or not wallet
      totalWithdrawalAmount = math.add(wallet.withdrawal_fee, payment.amount)
      GLOBAL.db.sequelize.transaction (transaction)->
        wallet.addBalance totalWithdrawalAmount, transaction, (err, wallet)->
          if err
            console.error err
            return transaction.rollback().success ()->
              return callback err
          payment.destroy().complete (err)->
            if err
              console.error err
              return transaction.rollback().success ()->
                return callback err
            transaction.commit().success ()->
              callback null, "#{payment.id} - removed"
              usersSocket.send
                type: "wallet-balance-changed"
                user_id: wallet.user_id
                eventData: JsonRenderer.wallet wallet
            transaction.done (err)->
              if err
                console.error err
                callback err

  pay: (payment, callback = ()->)->
    GLOBAL.wallets[payment.currency].sendToAddress payment.address, payment.getFloat("amount"), (err, response = "")->
      console.error "Could not withdraw to #{payment.address} #{payment.amount} BTC", err  if err
      return payment.errored err, callback  if err
      payment.process response, callback

  loadTransaction: (transactionData, currency, callback)->
    txId = transactionData.txid
    return callback()  if not txId
    MarketStats.findEnabledMarket currency, "BTC", (err, market)->
      if not market
        console.error "#{new Date()} - Will not load the transaction #{txId}, the market for #{currency} is disabled."
        return callback()
      category = transactionData.category
      address = transactionData.address
      return callback()  if not Transaction.isValidFormat category
      Wallet.findByAddress address, (err, wallet)->
        Transaction.addFromWallet transactionData, currency, wallet, (err, updatedTransaction)->
          if wallet
            usersSocket.send
              type: "transaction-update"
              user_id: updatedTransaction.user_id
              eventData: JsonRenderer.transaction updatedTransaction
            return callback()  if category isnt "receive" or updatedTransaction.balance_loaded or not GLOBAL.wallets[currency].isBalanceConfirmed(updatedTransaction.confirmations)
            GLOBAL.db.sequelize.transaction (transaction)->
              wallet.addBalance updatedTransaction.amount, transaction, (err)->
                if err
                  return transaction.rollback().success ()->
                    console.error "Could not load user balance #{updatedTransaction.amount} - #{err}"
                    return callback()
                Transaction.markAsLoaded updatedTransaction.id, transaction, (err)->
                  if err
                    return transaction.rollback().success ()->
                      console.error "Could not mark the transaction as loaded #{updatedTransaction.id} - #{err}"
                      return callback()
                  transaction.commit().success ()->
                    callback()
                    usersSocket.send
                      type: "wallet-balance-loaded"
                      user_id: wallet.user_id
                      eventData: JsonRenderer.wallet wallet
                  transaction.done (err)->
                    console.error "Could not load transaction #{updatedTransaction.id} - #{err}"  if err
                    return callback()
          else
            Payment.findByTransaction txId, (err, payment)->
              return callback()  if not payment
              Transaction.setUserAndWalletById txId, payment.user_id, payment.wallet_id, ()->
                callback()

exports = module.exports = TransactionHelper