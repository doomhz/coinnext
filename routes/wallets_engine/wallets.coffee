restify = require "restify"
Wallet = require "../../models/wallet"

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
