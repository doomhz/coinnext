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
    #console.log txId
    #console.log currency
    GLOBAL.wallets[currency].getTransaction txId, (err, transaction)->
      console.error err  if err
      if transaction and transaction.details[0].category isnt "move"
        Wallet.findByAccount transaction.details[0].account, (err, wallet)->
          Transaction.addFromWallet transaction, currency, wallet, ()->
            if wallet
              loadEntireAccountBalance wallet, ()->
                res.end()
            else
              res.end()
      else
        res.end()

  app.post "/process_pending_payments", (req, res, next)->
    processedUserIds = []
    processPaymentCallback = (payment, callback)->      
      Wallet.findById payment.wallet_id, (err, wallet)->
        if wallet
          if processedUserIds.indexOf(wallet.user_id) is -1
            if wallet.canWithdraw payment.amount
              wallet.addBalance -payment.amount, (err)->
                if not err
                  processPayment payment, (err, p)->
                    if p.isProcessed()
                      processedUserIds.push wallet.user_id
                      callback null, "#{payment.id} - processed"
                    else
                      wallet.addBalance payment.amount, ()->
                      callback null, "#{payment.id} - not processed - #{err}"
                else
                  callback null, "#{payment.id} - not processed - #{err}"
            else
              callback null, "#{payment.id} - not processed - no funds"
          else
            callback null, "#{payment.id} - user already had a processed payment"
        else
          callback null, "#{payment.id} - wallet #{payment.wallet_id} not found"
    Payment.find({status: "pending"}).exec (err, payments)->
      async.mapSeries payments, processPaymentCallback, (err, result)->
        console.log err  if err
        res.send(result)


  loadEntireAccountBalance = (wallet, callback = ()->)->
    GLOBAL.wallets[wallet.currency].getBalance wallet.account, (err, balance)=>
      if err
        console.error "Could not get balance for #{wallet.account}", err
        callback err, @
      else
        if balance isnt 0
          GLOBAL.wallets[wallet.currency].chargeAccount wallet.account, -balance, (err, success)=>
            if err
              console.error "Could not charge #{wallet.account} #{balance} BTC", err
              callback err, @
            else
              wallet.addBalance balance, callback
        else
          Wallet.findById wallet.id, callback

  processPayment = (payment, callback = ()->)->
    account = GLOBAL.wallets[payment.currency].account
    GLOBAL.wallets[payment.currency].sendToAddress payment.address, account, payment.amount, (err, response = "")=>
      if err
        console.error "Could not withdraw to #{payment.address} from #{account} #{payment.amount} BTC", err
        payment.errored JSON.stringify(err), callback
      else
        payment.process JSON.stringify(response), callback
