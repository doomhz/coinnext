restify = require "restify"
Wallet = require "../../models/wallet"

module.exports = (app)->

  app.post "/create_account/:account/:currency", (req, res, next)->
    account   = req.params.account
    currency = req.params.currency
    return return next(new restify.ConflictError "Wrong Currency.")  if not GLOBAL.wallets[currency]
    GLOBAL.wallets[currency].generateAddress account, (err, address)->
      console.error err  if err
      return next(new restify.ConflictError "Could not generate address.")  if err
      res.send
        account: account
        address: address
