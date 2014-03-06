restify = require "restify"
async = require "async"
User = require "../../models/user"
Wallet = require "../../models/wallet"
Transaction = GLOBAL.db.Transaction
Payment = GLOBAL.db.Payment
JsonRenderer = require "../../lib/json_renderer"
ClientSocket = require "../../lib/client_socket"
usersSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "users"

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
    processedUserIds = []
    processPaymentCallback = (payment, callback)->      
      Wallet.findById payment.wallet_id, (err, wallet)->
        return callback null, "#{payment.id} - wallet #{payment.wallet_id} not found"  if not wallet
        return callback null, "#{payment.id} - user already had a processed payment"  if processedUserIds.indexOf(wallet.user_id) > -1
        return callback null, "#{payment.id} - not processed - no funds"  if not wallet.canWithdraw payment.amount
        wallet.addBalance -payment.amount, (err)->
          return callback null, "#{payment.id} - not processed - #{err}"  if err
          processPayment payment, (err, p)->
            if not err and p.isProcessed()
              processedUserIds.push wallet.user_id
              Transaction.setUserById p.transaction_id, p.user_id, ()->
                callback null, "#{payment.id} - processed"
                usersSocket.send
                  type: "payment-processed"
                  user_id: payment.user_id
                  eventData: JsonRenderer.payment p
            else
              wallet.addBalance payment.amount, ()->
                callback null, "#{payment.id} - not processed - #{err}"
          
    Payment.findByStatus "pending", (err, payments)->
      async.mapSeries payments, processPaymentCallback, (err, result)->
        console.log err  if err
        res.send("#{new Date()} - #{result}")


  processPayment = (payment, callback = ()->)->
    account = null
    console.log payment.address
    GLOBAL.wallets[payment.currency].sendToAddress payment.address, payment.amount, (err, response = "")=>
      console.error "Could not withdraw to #{payment.address} #{payment.amount} BTC", err  if err
      return payment.errored err, callback  if err
      payment.process response, callback

  loadTransaction = (transactionOrId, currency, callback)->
    txId = if typeof(transactionOrId) is "string" then transactionOrId else transactionOrId.txid
    return callback()  if not txId
    GLOBAL.wallets[currency].getTransaction txId, (err, transaction)->
      console.error err  if err
      return callback()  if err
      category = transaction.details[0].category
      account = transaction.details[0].account
      return callback()  if not Transaction.isValidFormat category
      Wallet.findByAccount account, (err, wallet)->
        Transaction.addFromWallet transaction, currency, wallet, (err, updatedTransaction)->
          if wallet
            usersSocket.send
              type: "transaction-update"
              user_id: updatedTransaction.user_id
              eventData: JsonRenderer.transaction updatedTransaction
            return callback()  if category isnt "receive" or updatedTransaction.balance_loaded or not GLOBAL.wallets[currency].isBalanceConfirmed(updatedTransaction.confirmations)
            wallet.addBalance updatedTransaction.amount, (err)->
              console.error "Could not load user balance #{updatedTransaction.amount}", err  if err
              return callback()  if err
              console.log "Added balance #{updatedTransaction.amount} to wallet #{wallet.id} for tx #{updatedTransaction.id}", err  if err
              Transaction.markAsLoaded updatedTransaction.id, ()->
                console.log "Balance loading to wallet #{wallet.id} for tx #{updatedTransaction.id} finished", err  if err
                callback()
                usersSocket.send
                  type: "wallet-balance-loaded"
                  user_id: wallet.user_id
                  eventData: JsonRenderer.wallet wallet
          else
            Payment.findByTransaction txId, (err, payment)->
              return callback()  if not payment
              Transaction.setUserAndWalletById txId, payment.user_id, payment.wallet_id, ()->
                callback()
