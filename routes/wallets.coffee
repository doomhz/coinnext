Wallet = require "../models/wallet"
_ = require "underscore"

module.exports = (app)->

  app.post "/wallets", (req, res)->
    currency = req.body.currency
    console.log currency
    console.log req.body
    if req.user
      Wallet.findUserWalletByCurrency req.user.id, currency, (err, wallet)->
        if not wallet
          wallet = new Wallet
            user_id: req.user.id
            currency: currency
          wallet.save (err, wl)->
            return renderError "Sorry, can not create a wallet at this time...", res  if err
            res.json wl
        else
          renderError "A wallet of this currency already exists.", res

  app.get "/wallets", (req, res)->
    if req.user
      Wallet.findUserWallets req.user.id, (err, wallets)->
        console.error err  if err
        res.json wallets

  renderError = (err, res, code = 409)->
    res.statusCode = code
    message = ""
    if _.isString err
      message = err
    else if _.isObject(err) and err.name is "ValidationError"
      for key, val of err.errors
        if val.path is "email" and val.message is "unique"
          message += "E-mail is already taken. "
        else
          message += "#{val.message} "
    res.json {error: message}
