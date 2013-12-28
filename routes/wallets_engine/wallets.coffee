restify = require "restify"
Wallet = require "../../models/wallet"

module.exports = (app)->

  app.post "/create_account/:account/:currency", (req, res, next)->
    account   = req.params.account
    currency = req.params.currency
    if GLOBAL.wallets[currency]
      GLOBAL.wallets[currency].generateAddress account, (err, address)->
        if not err
          return res.send
            account: account
            address: address
        else
          return next(new restify.ConflictError "Could not generate address.")
    else
      return next(new restify.ConflictError "Wrong Currency.")
