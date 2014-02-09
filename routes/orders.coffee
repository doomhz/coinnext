Order = require "../models/order"
Wallet = require "../models/wallet"
MarketStats = require "../models/market_stats"
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.post "/orders", (req, res)->
    return JsonRenderer.error "You need to be logged in to place an order.", res  if not req.user
    return JsonRenderer.error "Sorry, but you can not trade. Did you verify your account?", res  if not req.user.canTrade()
    data = req.body
    data.user_id = req.user.id
    return JsonRenderer.error validationError, res  if validationError = notValidOrderData data
    holdBalance = data.amount
    Wallet.findOrCreateUserWalletByCurrency req.user.id, data.buy_currency, (err, buyWallet)->
      return JsonRenderer.error "Wallet #{data.buy_currency} does not exist.", res  if err or not buyWallet
      Wallet.findOrCreateUserWalletByCurrency req.user.id, data.sell_currency, (err, wallet)->
        return JsonRenderer.error "Wallet #{data.sell_currency} does not exist.", res  if err or not wallet
        wallet.holdBalance holdBalance, (err, wallet)->
          return JsonRenderer.error "Not enough #{data.sell_currency} to open an order.", res  if err or not wallet
          Order.create data, (err, newOrder)->
            return JsonRenderer.error "Sorry, could not open an order...", res  if err
            newOrder.publish (err, order)->
              console.log "Could not publish newlly created order - #{err}"  if err
              return res.json JsonRenderer.order newOrder  if err
              res.json JsonRenderer.order order

  app.get "/orders", (req, res)->
    Order.findByOptions req.query, (err, orders)->
      return JsonRenderer.error "Sorry, could not get open orders...", res  if err
      res.json JsonRenderer.orders orders

  app.del "/orders/:id", (req, res)->
    return JsonRenderer.error "You need to be logged in to delete an order.", res  if not req.user
    Order.findOne {user_id: req.user.id, _id: req.params.id}, (err, order)->
      return JsonRenderer.error "Sorry, could not delete orders...", res  if err or not order
      order.cancel (err)->
        console.log "Could not cancel order - #{err}"  if err
        return res.json JsonRenderer.order order  if err
        res.json {}

  notValidOrderData = (orderData)->
    return "Please submit a valid amount bigger than 0."  if not Order.isValidTradeAmount orderData.amount
    return "Please submit a valid unit price amount."  if orderData.type is "limit" and not Order.isValidTradeAmount(parseFloat(orderData.unit_price))
    return "Please submit a valid action."  if ["buy", "sell"].indexOf(orderData.action) is -1
    return "Please submit a valid buy currency."  if Wallet.getCurrencies().indexOf(orderData.buy_currency) is -1
    return "Please submit a valid sell currency."  if Wallet.getCurrencies().indexOf(orderData.sell_currency) is -1
    return "Please submit different currencies."  if orderData.buy_currency is orderData.sell_currency
    return "Invalid market."  if not MarketStats.isValidMarket orderData.action, orderData.buy_currency, orderData.sell_currency
    false
