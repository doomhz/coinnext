restify = require "restify"
Wallet = require "../../models/wallet"

module.exports = (app)->

  app.post "/create_account/:user_id/:currency", (req, res, next)->
    userId   = req.params.user_id
    currency = req.params.currency
    if userId and GLOBAL.wallets[currency]
      GLOBAL.wallets[currency].generateAddress userId, (err, address)->
        if not err
          res.send
            account: userId
            address: address
          return next()
        else
          return next(new restify.ConflictError "Could not generate address.")
    else
      return next(new restify.ConflictError "Wrong user ID or Currency.")
