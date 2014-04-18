Wallet = GLOBAL.db.Wallet
Transaction = GLOBAL.db.Transaction
Payment = GLOBAL.db.Payment
MarketStats = GLOBAL.db.MarketStats
JsonRenderer = require "./json_renderer"
ClientSocket = require "./client_socket"
usersSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "users"

TransactionHelper =

  paymentsProcessedUserIds: []

  pushToUser: (data)->
    usersSocket.send data

  processPayment: (payment, callback)->
    MarketStats.findEnabledMarket payment.currency, "BTC", (err, market)->
      return callback null, "#{new Date()} - Will not process payment #{payment.id}, the market for #{payment.currency} is disabled."  if not market
      Wallet.findById payment.wallet_id, (err, wallet)->
        return callback null, "#{payment.id} - wallet #{payment.wallet_id} not found"  if not wallet
        return callback null, "#{payment.id} - user already had a processed payment"  if TransactionHelper.paymentsProcessedUserIds.indexOf(wallet.user_id) > -1
        return callback null, "#{payment.id} - not processed - no funds"  if not wallet.canWithdraw payment.amount
        GLOBAL.db.sequelize.transaction (transaction)->
          wallet.addBalance -payment.amount, transaction, (err)->
            if err
              return transaction.rollback().success ()->
                callback null, "#{payment.id} - not processed - #{err}"
            wallet.addBalance -wallet.withdrawal_fee, transaction, (err)->
              if err
                return transaction.rollback().success ()->
                  callback null, "#{payment.id} - not processed - #{err}"
              TransactionHelper.pay payment, (err, p)->
                if err or not p.isProcessed()
                  return transaction.rollback().success ()->
                    callback null, "#{payment.id} - not processed - #{err}"
                transaction.commit().success ()->
                  TransactionHelper.paymentsProcessedUserIds.push wallet.user_id
                  Transaction.setUserById p.transaction_id, p.user_id, ()->
                    callback null, "#{payment.id} - processed"
                    usersSocket.send
                      type: "payment-processed"
                      user_id: payment.user_id
                      eventData: JsonRenderer.payment p
                transaction.done (err)->
                  callback null, "#{payment.id} - not processed - #{err}"  if err

  pay: (payment, callback = ()->)->
    GLOBAL.wallets[payment.currency].sendToAddress payment.address, payment.amount, (err, response = "")->
      console.error "Could not withdraw to #{payment.address} #{payment.amount} BTC", err  if err
      return payment.errored err, callback  if err
      payment.process response, callback

  loadTransaction: (transactionOrId, currency, callback)->
    txId = if typeof(transactionOrId) is "string" then transactionOrId else transactionOrId.txid
    return callback()  if not txId
    MarketStats.findEnabledMarket currency, "BTC", (err, market)->
      if not market
        console.error "#{new Date()} - Will not load the transaction #{txId}, the market for #{currency} is disabled."
        return callback()
      GLOBAL.wallets[currency].getTransaction txId, (err, walletTransaction)->
        console.error err  if err
        return callback()  if err
        category = walletTransaction.details[0].category
        address = walletTransaction.details[0].address
        return callback()  if not Transaction.isValidFormat category
        Wallet.findByAddress address, (err, wallet)->
          Transaction.addFromWallet walletTransaction, currency, wallet, (err, updatedTransaction)->
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
                      console.error "Could not load transaction #{updatedTransaction.id} - #{err}"
                      return callback()
            else
              Payment.findByTransaction txId, (err, payment)->
                return callback()  if not payment
                Transaction.setUserAndWalletById txId, payment.user_id, payment.wallet_id, ()->
                  callback()

exports = module.exports = TransactionHelper