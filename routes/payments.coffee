Payment = GLOBAL.db.Payment
Wallet = GLOBAL.db.Wallet
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.post "/payments", (req, res)->
    amount = req.body.amount
    walletId = req.body.wallet_id
    address = req.body.address
    return JsonRenderer.error "Please auth.", res  if not req.user
    Wallet.findUserWallet req.user.id, walletId, (err, wallet)->
      return JsonRenderer.error "Wrong wallet.", res  if not wallet
      return JsonRenderer.error "You don't have enough funds.", res  if not wallet.canWithdraw amount, true
      return JsonRenderer.error "You can't withdraw to the same address.", res  if address is wallet.address
      data =
        user_id: req.user.id
        wallet_id: walletId
        currency: wallet.currency
        amount: amount
        address: address
      Payment.create(data).complete (err, pm)->
        return JsonRenderer.error err, res  if err
        res.json JsonRenderer.payment pm

  app.get "/payments/pending/:wallet_id", (req, res)->
    walletId = req.params.wallet_id
    return JsonRenderer.error "Please auth.", res  if not req.user
    Payment.findByUserAndWallet req.user.id, walletId, "pending", (err, payments)->
      console.error err  if err
      return JsonRenderer.error "Sorry, could not get pending payments...", res  if err
      res.json JsonRenderer.payments payments
