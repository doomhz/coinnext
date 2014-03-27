restify = require "restify"
async = require "async"
Wallet = GLOBAL.db.Wallet
Transaction = GLOBAL.db.Transaction
Payment = GLOBAL.db.Payment
JsonRenderer = require "../../lib/json_renderer"
ClientSocket = require "../../lib/client_socket"
usersSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "users"
paymentsProcessedUserIds = []

module.exports = (app)->

  app.put "/transaction/:currency/:tx_id", (req, res, next)->
    txId = req.params.tx_id
    currency = req.params.currency
    console.log txId
    console.log currency
    loadTransaction txId, currency, ()->
      res.end()

  app.post "/load_latest_transactions/:currency", (req, res, next)->
    currency = req.params.currency
    GLOBAL.wallets[currency].getTransactions "*", 100, 0, (err, transactions)->
      console.error err  if err
      loadTransactionCallback = (transaction, callback)->
        loadTransaction transaction, currency, callback
      return res.send("#{new Date()} - Nothing to process")  if not transactions
      async.mapSeries transactions, loadTransactionCallback, (err, result)->
        console.error err  if err
        res.send("#{new Date()} - Processed #{result.length} transactions")        

  app.post "/process_pending_payments", (req, res, next)->
    paymentsProcessedUserIds = []
    Payment.findByStatus "pending", (err, payments)->
      async.mapSeries payments, processPayment, (err, result)->
        console.log err  if err
        res.send("#{new Date()} - #{result}")

  app.post "/process_payment/:payment_id", (req, res, next)->
    paymentId = req.params.payment_id
    paymentsProcessedUserIds = []
    Payment.findById paymentId, (err, payment)->
      processPayment payment, (err, result)->
        Payment.findById paymentId, (err, processedPayment)->
          res.send
            paymentId: paymentId
            status: processedPayment.status
            result: result
          if processedPayment.isProcessed()
            usersSocket.send
              type: "payment-processed"
              user_id: payment.user_id
              eventData: JsonRenderer.payment processedPayment


  # TODO: Move to a separate component
  processPayment = (payment, callback)->      
    Wallet.findById payment.wallet_id, (err, wallet)->
      return callback null, "#{payment.id} - wallet #{payment.wallet_id} not found"  if not wallet
      return callback null, "#{payment.id} - user already had a processed payment"  if paymentsProcessedUserIds.indexOf(wallet.user_id) > -1
      return callback null, "#{payment.id} - not processed - no funds"  if not wallet.canWithdraw payment.amount
      GLOBAL.db.sequelize.transaction (transaction)->
        wallet.addBalance -payment.amount, transaction, (err)->
          if err
            return transaction.rollback().success ()->
              callback null, "#{payment.id} - not processed - #{err}"
          pay payment, (err, p)->
            if err or not p.isProcessed()
              return transaction.rollback().success ()->
                callback null, "#{payment.id} - not processed - #{err}"
            transaction.commit().success ()->
              paymentsProcessedUserIds.push wallet.user_id
              Transaction.setUserById p.transaction_id, p.user_id, ()->
                callback null, "#{payment.id} - processed"
                usersSocket.send
                  type: "payment-processed"
                  user_id: payment.user_id
                  eventData: JsonRenderer.payment p
            transaction.done (err)->
              callback null, "#{payment.id} - not processed - #{err}"

  # TODO: Move to a separate component
  pay = (payment, callback = ()->)->
    GLOBAL.wallets[payment.currency].sendToAddress payment.address, payment.amount, (err, response = "")->
      console.error "Could not withdraw to #{payment.address} #{payment.amount} BTC", err  if err
      return payment.errored err, callback  if err
      payment.process response, callback

  # TODO: Move to a separate component
  loadTransaction = (transactionOrId, currency, callback)->
    txId = if typeof(transactionOrId) is "string" then transactionOrId else transactionOrId.txid
    return callback()  if not txId
    GLOBAL.wallets[currency].getTransaction txId, (err, walletTransaction)->
      console.error err  if err
      return callback()  if err
      category = walletTransaction.details[0].category
      account = walletTransaction.details[0].account
      return callback()  if not Transaction.isValidFormat category
      Wallet.findByAccount account, (err, wallet)->
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
                    next(new restify.ConflictError "Could not load user balance #{updatedTransaction.amount} - #{err}")
                Transaction.markAsLoaded updatedTransaction.id, transaction, (err)->
                  if err
                    return transaction.rollback().success ()->
                      next(new restify.ConflictError "Could not mark the transaction as loaded #{updatedTransaction.id} - #{err}")
                  transaction.commit().success ()->
                    callback()
                    usersSocket.send
                      type: "wallet-balance-loaded"
                      user_id: wallet.user_id
                      eventData: JsonRenderer.wallet wallet
                  transaction.done (err)->
                    next(new restify.ConflictError "Could not load transaction #{updatedTransaction.id} - #{err}")
          else
            Payment.findByTransaction txId, (err, payment)->
              return callback()  if not payment
              Transaction.setUserAndWalletById txId, payment.user_id, payment.wallet_id, ()->
                callback()
