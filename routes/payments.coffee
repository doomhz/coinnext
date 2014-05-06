Payment = GLOBAL.db.Payment
Wallet = GLOBAL.db.Wallet
MarketHelper = require "../lib/market_helper"
JsonRenderer = require "../lib/json_renderer"
_ = require "underscore"

module.exports = (app)->

  app.post "/payments", (req, res)->
    amount = parseFloat req.body.amount
    return JsonRenderer.error "Please auth.", res  if not req.user
    return JsonRenderer.error "Please submit a valid amount.", res  if not _.isNumber(amount) or _.isNaN(amount) or not _.isFinite(amount)
    data =
      user_id: req.user.id
      wallet_id: req.body.wallet_id
      amount: MarketHelper.toBigint amount
      address: req.body.address
    Payment.submit data, (err, payment)->
      return JsonRenderer.error err, res  if err
      res.json JsonRenderer.payment payment

  app.get "/payments/pending/:wallet_id", (req, res)->
    walletId = req.params.wallet_id
    return JsonRenderer.error "Please auth.", res  if not req.user
    Payment.findByUserAndWallet req.user.id, walletId, "pending", (err, payments)->
      console.error err  if err
      return JsonRenderer.error "Sorry, could not get pending payments...", res  if err
      res.json JsonRenderer.payments payments
