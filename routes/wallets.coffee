Wallet = require "../models/wallet"
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.post "/wallets", (req, res)->
    currency = req.body.currency
    if req.user
      Wallet.findUserWalletByCurrency req.user.id, currency, (err, wallet)->
        if not wallet
          wallet = new Wallet
            user_id: req.user.id
            currency: currency
          wallet.save (err, wl)->
            return JsonRenderer.error "Sorry, can not create a wallet at this time...", res  if err
            res.json JsonRenderer.wallet wl
        else
          JsonRenderer.error "A wallet of this currency already exists.", res
    else
      JsonRenderer.error "Please auth.", res

  app.get "/wallets", (req, res)->
    if req.user
      Wallet.findUserWallets req.user.id, (err, wallets)->
        console.error err  if err
        res.json JsonRenderer.wallets wallets
    else
      JsonRenderer.error "Please auth.", res

  app.put "/wallets/:id", (req, res)->
    if req.user
      Wallet.findUserWallet req.user.id, req.body.id, (err, wallet)->
        console.error err  if err
        if wallet
          if req.body.address is "pending"
            wallet.generateAddress (err, wallet)->
              res.json JsonRenderer.wallet wallet
          else
            res.json JsonRenderer.wallet wallet
        else
          JsonRenderer.error "Wrong wallet.", res
    else
      JsonRenderer.error "Please auth.", res
