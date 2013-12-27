restify = require "restify"
User = require "../../models/user"
Wallet = require "../../models/wallet"
Transaction = require "../../models/transaction"

module.exports = (app)->

  app.post "/create_account/:user_id/:currency", (req, res, next)->
    userId   = req.params.user_id
    currency = req.params.currency
    if GLOBAL.wallets[currency]
      GLOBAL.wallets[currency].generateAddress userId, (err, address)->
        if not err
          return res.send
            account: userId
            address: address
        else
          return next(new restify.ConflictError "Could not generate address.")
    else
      return next(new restify.ConflictError "Wrong Currency.")

  app.put "/transaction/:currency/:tx_id", (req, res, next)->
    txId = req.params.tx_id
    currency = req.params.currency
    #console.log txId
    #console.log currency
    GLOBAL.wallets[currency].getTransaction txId, (err, transaction)->
      console.error err  if err
      if transaction and transaction.details[0].category isnt "move"
        if transaction.details[0].account
          User.findById transaction.details[0].account, (err, user)->
            if user
              Wallet.findUserWalletByCurrency user.id, currency, (err, wallet)->
                Transaction.addFromWallet transaction, currency, user, wallet
            else
              Transaction.addFromWallet transaction, currency, user
        else
          Transaction.addFromWallet transaction, currency
    res.end()
