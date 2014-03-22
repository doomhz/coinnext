Wallet = GLOBAL.db.Wallet
MarketHelper = require "../lib/market_helper"
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.post "/wallets", (req, res)->
    currency = req.body.currency
    return JsonRenderer.error "Please auth.", res  if not req.user
    return JsonRenderer.error "Invalid currency.", res  if not MarketHelper.isValidCurrency currency
    Wallet.findOrCreateUserWalletByCurrency req.user.id, currency, (err, wallet)->
      console.error err  if err
      return JsonRenderer.error "Could not create wallet.", res  if err
      res.json JsonRenderer.wallet wallet      

  app.put "/wallets/:id", (req, res)->
    return JsonRenderer.error "Please auth.", res  if not req.user
    Wallet.findUserWallet req.user.id, req.params.id, (err, wallet)->
      console.error err  if err
      return JsonRenderer.error "Wrong wallet.", res  if err
      return res.json JsonRenderer.wallet wallet  if wallet.address
      wallet.generateAddress (err, wl)->
        console.error err  if err
        return JsonRenderer.error "Could not generate address.", res  if err
        res.json JsonRenderer.wallet wl

  app.get "/wallets/:id", (req, res)->
    return JsonRenderer.error "Please auth.", res  if not req.user
    Wallet.findUserWallet req.user.id, req.params.id, (err, wallet)->
      console.error err  if err
      return JsonRenderer.error "Wrong wallet.", res  if err
      return res.json JsonRenderer.wallet wallet

  app.get "/wallets", (req, res)->
    return JsonRenderer.error "Please auth.", res  if not req.user
    Wallet.findUserWallets req.user.id, (err, wallets)->
      console.error err  if err
      res.json JsonRenderer.wallets wallets
