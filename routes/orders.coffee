Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
MarketHelper = require "../lib/market_helper"
JsonRenderer = require "../lib/json_renderer"
ClientSocket = require "../lib/client_socket"
usersSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "users"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

module.exports = (app)->

  app.post "/orders", (req, res)->
    return JsonRenderer.error "You need to be logged in to place an order.", res  if not req.user
    return JsonRenderer.error "Sorry, but you can not trade. Did you verify your account?", res  if not req.user.canTrade()
    data = req.body
    data.user_id = req.user.id
    data.status = "open"
    return JsonRenderer.error validationError, res  if validationError = notValidOrderData data
    orderCurrency = data["#{data.action}_currency"]
    MarketStats.findEnabledMarket orderCurrency, "BTC", (err, market)->
      return JsonRenderer.error "Can't submit the order, the #{orderCurrency} market is closed at the moment.", res  if not market
      holdBalance = math.multiply(parseFloat(data.amount), parseFloat(data.unit_price))  if data.type is "limit" and data.action is "buy"
      holdBalance = parseFloat(data.amount)  if data.type is "limit" and data.action is "sell"
      Wallet.findOrCreateUserWalletByCurrency req.user.id, data.buy_currency, (err, buyWallet)->
        return JsonRenderer.error "Wallet #{data.buy_currency} does not exist.", res  if err or not buyWallet
        Wallet.findOrCreateUserWalletByCurrency req.user.id, data.sell_currency, (err, wallet)->
          return JsonRenderer.error "Wallet #{data.sell_currency} does not exist.", res  if err or not wallet
          GLOBAL.db.sequelize.transaction (transaction)->
            wallet.holdBalance holdBalance, transaction, (err, wallet)->
              if err or not wallet
                console.error err
                return transaction.rollback().success ()->
                  JsonRenderer.error "Not enough #{data.sell_currency} to open an order.", res
              Order.create(data, {transaction: transaction}).complete (err, newOrder)->
                if err
                  console.error err
                  return transaction.rollback().success ()->
                    JsonRenderer.error "Sorry, could not open an order...", res
                transaction.commit().success ()->
                  newOrder.publish (err, order)->
                    console.error "Could not publish newlly created order - #{err}"  if err
                    return res.json JsonRenderer.order newOrder  if err
                    res.json JsonRenderer.order order
                  usersSocket.send
                    type: "wallet-balance-changed"
                    user_id: wallet.user_id
                    eventData: JsonRenderer.wallet wallet
                transaction.done (err)->
                  JsonRenderer.error "Could not open an order. Please try again later.", res  if err

  app.get "/orders", (req, res)->
    Order.findByOptions req.query, (err, orders)->
      return JsonRenderer.error "Sorry, could not get open orders...", res  if err
      res.json JsonRenderer.orders orders

  app.del "/orders/:id", (req, res)->
    return JsonRenderer.error "You need to be logged in to delete an order.", res  if not req.user
    Order.findByUserAndId req.params.id, req.user.id, (err, order)->
      return JsonRenderer.error "Sorry, could not delete orders...", res  if err or not order
      order.cancel (err)->
        console.error "Could not cancel order - #{err}"  if err
        return res.json JsonRenderer.order order  if err
        res.json {}

  # TODO: Move to the model as field validations
  notValidOrderData = (orderData)->
    return "Market orders are disabled at the moment."  if orderData.type is "market"
    return "Please submit a valid amount bigger than 0.0000001."  if not Order.isValidTradeAmount orderData.amount
    return "Please submit a valid unit price amount."  if orderData.type is "limit" and not Order.isValidTradeAmount(parseFloat(orderData.unit_price))
    return "Please submit a valid action."  if not MarketHelper.getOrderAction orderData.action
    return "Please submit a valid buy currency."  if not MarketHelper.isValidCurrency orderData.buy_currency
    return "Please submit a valid sell currency."  if not MarketHelper.isValidCurrency orderData.sell_currency
    return "Please submit different currencies."  if orderData.buy_currency is orderData.sell_currency
    return "Invalid market."  if not MarketHelper.isValidMarket orderData.action, orderData.buy_currency, orderData.sell_currency
    return "Trade amount is too low, please submit a bigger amount."  if not Order.isValidSpendAmount orderData.amount, orderData.action, orderData.unit_price
    return "The fee is too low, please submit a bigger amount."  if not Order.isValidFee orderData.amount, orderData.action, orderData.unit_price
    false
