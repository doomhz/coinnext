Payment = GLOBAL.db.Payment
Wallet = GLOBAL.db.Wallet
MarketHelper = require "../lib/market_helper"
JsonRenderer = require "../lib/json_renderer"
ClientSocket = require "../lib/client_socket"
_ = require "underscore"
usersSocket = new ClientSocket
  namespace: "users"
  redis: GLOBAL.appConfig().redis
math = require("mathjs")
  number: "bignumber"
  decimals: 8

module.exports = (app)->

  app.post "/payments", (req, res)->
    amount = parseFloat req.body.amount
    return JsonRenderer.error "Please auth.", res  if not req.user
    return JsonRenderer.error "Please submit a valid amount.", res  if not _.isNumber(amount) or _.isNaN(amount) or not _.isFinite(amount)
    amount = MarketHelper.toBigint amount
    walletId = req.body.wallet_id
    address = req.body.address
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
      GLOBAL.db.sequelize.transaction (transaction)->
        Payment.create(data, {transaction: transaction}).complete (err, pm)->
          if err
            console.error err
            return transaction.rollback().success ()->
              JsonRenderer.error "Sorry, could not submit the withdrawal...", res
          totalWithdrawalAmount = math.add(wallet.withdrawal_fee, pm.amount)
          wallet.addBalance -totalWithdrawalAmount, transaction, (err, wallet)->
            if err
              console.error err
              return transaction.rollback().success ()->
                JsonRenderer.error "Sorry, could not submit the withdrawal...", res
            transaction.commit().success ()->
              res.json JsonRenderer.payment pm
              usersSocket.send
                type: "wallet-balance-changed"
                user_id: wallet.user_id
                eventData: JsonRenderer.wallet wallet
            transaction.done (err)->
              JsonRenderer.error "Sorry, could not submit the withdrawal...", res  if err

  app.get "/payments/pending/:wallet_id", (req, res)->
    walletId = req.params.wallet_id
    return JsonRenderer.error "Please auth.", res  if not req.user
    Payment.findByUserAndWallet req.user.id, walletId, "pending", (err, payments)->
      console.error err  if err
      return JsonRenderer.error "Sorry, could not get pending payments...", res  if err
      res.json JsonRenderer.payments payments
