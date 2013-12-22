Payment = require "../models/payment"
Wallet = require "../models/wallet"
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.post "/payments", (req, res)->
    amount = req.body.amount
    walletId = req.body.wallet_id
    address = req.body.address
    if req.user
      Wallet.findUserWallet req.user.id, walletId, (err, wallet)->
        if wallet
          if wallet.canWithdraw amount
            payment = new Payment
              user_id: req.user.id
              wallet_id: walletId
              amount: amount
              address: address
            payment.save (err, pm)->
              return JsonRenderer.error "Sorry, could not schedule a payment...", res  if err
              res.json JsonRenderer.payment pm
          else
            JsonRenderer.error "You don't have enough funds.", res
        else
          JsonRenderer.error "Wrong wallet.", res
    else
      JsonRenderer.error "Please auth.", res
