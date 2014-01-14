Order = require "../models/order"
Wallet = require "../models/wallet"
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.post "/orders", (req, res)->
    if req.user
      data = req.body
      data.user_id = req.user.id
      Wallet.findUserWalletByCurrency req.user.id, data.buy_currency, (err, buyWallet)->
        return JsonRenderer.error "Wallet #{data.buy_currency} does not exist.", res  if err or not buyWallet
        Wallet.findUserWalletByCurrency req.user.id, data.sell_currency, (err, wallet)->
          return JsonRenderer.error "Wallet #{data.sell_currency} does not exist.", res  if err or not wallet
          wallet.holdBalance parseFloat(data.amount), (err, wallet)->
            return JsonRenderer.error "Not enough #{data.sell_currency} to open an order.", res  if err or not wallet
            Order.create data, (err, order)->
              return JsonRenderer.error "Sorry, could not open an order...", res  if err
              res.json JsonRenderer.order order
    else
      JsonRenderer.error "Please auth.", res

  app.get "/orders/open/:currency1/:currency2", (req, res)->
    currency1 = req.body.currency1
    currency2 = req.body.currency2
    if req.user
      Order.findOpenByUserAndCurrencies req.user.id, [currency1, currency2], (err, transactions)->
        console.error err  if err
        return JsonRenderer.error "Sorry, could not get open orders...", res  if err
        res.json JsonRenderer.orders orders
    else
      JsonRenderer.error "Please auth.", res
