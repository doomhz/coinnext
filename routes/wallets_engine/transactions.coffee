restify = require "restify"
async = require "async"
User = require "../../models/user"
Wallet = require "../../models/wallet"
Transaction = require "../../models/transaction"
Payment = require "../../models/payment"

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
            if p.isProcessed()
              processedUserIds.push wallet.user_id
              Transaction.update {txid: p.transaction_id}, {user_id: p.user_id}, ()->
                callback null, "#{payment.id} - processed"
            else
              wallet.addBalance payment.amount, ()->
                callback null, "#{payment.id} - not processed - #{err}"
          
    Payment.find({status: "pending"}).sort({created: "asc"}).exec (err, payments)->
      async.mapSeries payments, processPaymentCallback, (err, result)->
        console.log err  if err
        res.send("#{new Date()} - #{result}")


  loadEntireAccountBalance = (wallet, callback = ()->)->
    GLOBAL.wallets[wallet.currency].getBalance wallet.account, (err, balance)=>
      console.error "Could not get balance for #{wallet.account}", err  if err
      return callback err, @  if err
      return Wallet.findById wallet.id, callback  if balance <= 0
      GLOBAL.wallets[wallet.currency].chargeAccount wallet.account, -balance, (err, success)=>
        console.error "Could not charge #{wallet.account} #{balance} BTC", err  if err
        return callback err, @  if err
        wallet.addBalance balance, callback

  processPayment = (payment, callback = ()->)->
    account = null
    console.log payment.address
    GLOBAL.wallets[payment.currency].sendToAddress payment.address, account, payment.amount, (err, response = "")=>
      console.error "Could not withdraw to #{payment.address} from #{account} #{payment.amount} BTC", err  if err
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
        Transaction.addFromWallet transaction, currency, wallet, ()->
          if wallet
            return callback()  if category isnt "receive"
            loadEntireAccountBalance wallet, ()->
              callback()
          else
            Payment.findOne {transaction_id: txId}, (err, payment)->
              return callback()  if not payment
              Transaction.update {txid: txId}, {user_id: payment.user_id, wallet_id: payment.wallet_id}, ()->
                callback()
