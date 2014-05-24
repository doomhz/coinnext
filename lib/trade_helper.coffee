request = require "request"
Order = GLOBAL.db.Order
OrderLog = GLOBAL.db.OrderLog
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
JsonRenderer = require "./json_renderer"
MarketHelper = require "./market_helper"
ClientSocket = require "./client_socket"
orderSocket = new ClientSocket
  namespace: "orders"
  redis: GLOBAL.appConfig().redis
usersSocket = new ClientSocket
  namespace: "users"
  redis: GLOBAL.appConfig().redis
math = require("mathjs")
  number: "bignumber"
  decimals: 8

TradeHelper =

  createOrder: (data, callback = ()->)->
    holdBalance = math.multiply(data.amount, MarketHelper.fromBigint(data.unit_price))  if data.type is "limit" and data.action is "buy"
    holdBalance = data.amount  if data.type is "limit" and data.action is "sell"
    Wallet.findOrCreateUserWalletByCurrency data.user_id, data.buy_currency, (err, buyWallet)->
      return callback "Wallet #{data.buy_currency} does not exist."  if err or not buyWallet
      Wallet.findOrCreateUserWalletByCurrency data.user_id, data.sell_currency, (err, wallet)->
        return callback "Wallet #{data.sell_currency} does not exist."  if err or not wallet
        GLOBAL.db.sequelize.transaction (transaction)->
          wallet.holdBalance holdBalance, transaction, (err, wallet)->
            if err or not wallet
              console.error err
              return transaction.rollback().success ()->
                return callback "Not enough #{data.sell_currency} to open an order."
            Order.create(data, {transaction: transaction}).complete (err, newOrder)->
              if err
                console.error err
                return transaction.rollback().success ()->
                  return callback err
              transaction.commit().success ()->
                callback null, newOrder
                TradeHelper.pushUserUpdate
                  type: "wallet-balance-changed"
                  user_id: wallet.user_id
                  eventData: JsonRenderer.wallet wallet
              transaction.done (err)->
                return callback "Could not open an order. Please try again later."  if err

  cancelOrder: (orderId, callback = ()->)->
    Order.findById orderId, (err, order)->
      Wallet.findUserWalletByCurrency order.user_id, order.sell_currency, (err, wallet)->
        GLOBAL.db.sequelize.transaction (transaction)->
          wallet.holdBalance -order.left_hold_balance, transaction, (err, wallet)->
            if err or not wallet
              return transaction.rollback().success ()->
                callback "Could not cancel order #{orderId} - #{err}"
            order.destroy({transaction: transaction}).complete (err)->
              if err
                return transaction.rollback().success ()->
                  callback err
              transaction.commit().success ()->
                callback()
                TradeHelper.pushOrderUpdate
                  type: "order-canceled"
                  eventData:
                    id: orderId
                TradeHelper.pushUserUpdate
                  type: "wallet-balance-changed"
                  user_id: wallet.user_id
                  eventData: JsonRenderer.wallet wallet
              transaction.done (err)->
                callback "Could not cancel order #{orderId} - #{err}"  if err

  submitOrder: (order, callback = ()->)->
    orderData =
      order_id: order.id
      type: order.type
      action: order.action
      buy_currency: MarketHelper.getCurrency order.buy_currency
      sell_currency: MarketHelper.getCurrency order.sell_currency
      amount: order.amount
      unit_price: order.unit_price
    uri = "#{GLOBAL.appConfig().engine_api_host}/order/#{order.id}"
    options =
      uri: uri
      method: "POST"
      json: orderData
    @sendEngineData uri, options, callback

  sendEngineData: (uri, options, callback)->
    try
      request options, (err, response = {}, body)->
        if err or response.statusCode isnt 200
          err = "#{response.statusCode} - Could not send order data to #{uri} - #{JSON.stringify(options.json)} - #{JSON.stringify(err)} - #{JSON.stringify(body)}"
          console.error err
          return callback err
        return callback()
    catch e
      console.error e
      callback "Bad response #{e}"

  pushOrderUpdate: (data)->
    orderSocket.send data

  pushUserUpdate: (data)->
    usersSocket.send data

  matchOrders: (matchedData, callback)->
    delete matchedData[0].id
    delete matchedData[1].id
    GLOBAL.db.sequelize.transaction (transaction)->
      Order.findByIdWithTransaction matchedData[0].order_id, transaction, (err, orderToMatch)->
        return callback "Wrong order to complete #{matchedData[0].order_id} - #{err}"  if not orderToMatch or err or orderToMatch.status is "completed"
        Order.findByIdWithTransaction matchedData[1].order_id, transaction, (err, matchingOrder)->
          return callback "Wrong order to complete #{matchedData[1].order_id} - #{err}"  if not matchingOrder or err or orderToMatch.status is "completed"
          TradeHelper.updateMatchedOrder orderToMatch, matchedData[0], transaction, (err, updatedOrderToMatch, updatedOrderToMatchLog)->
            if err
              console.error "Could not process order #{orderToMatch.id}", err
              return transaction.rollback().success ()->
                callback "Could not process order #{orderToMatch.id} - #{err}"
            TradeHelper.updateMatchedOrder matchingOrder, matchedData[1], transaction, (err, updatedMatchingOrder, updatedMatchingOrderLog)->
              if err
                console.error "Could not process order #{matchingOrder.id}", err
                return transaction.rollback().success ()->
                  callback "Could not process order #{matchingOrder.id} - #{err}"
              transaction.commit().success ()->
                TradeHelper.trackMatchedOrder updatedOrderToMatchLog, ()->
                  TradeHelper.trackMatchedOrder updatedMatchingOrderLog
                callback()
              transaction.done (err)->
                if err
                  console.error "Could not process order #{orderId}", err
                  callback "Could not process order #{orderId} - #{err}"

  updateMatchedOrder: (orderToMatch, matchData, transaction, callback)->
    Wallet.findUserWalletByCurrency orderToMatch.user_id, orderToMatch.buy_currency, (err, buyWallet)->
      Wallet.findUserWalletByCurrency orderToMatch.user_id, orderToMatch.sell_currency, (err, sellWallet)->
        matchedAmount = matchData.matched_amount
        resultAmount = matchData.result_amount
        unitPrice = matchData.unit_price
        holdBalance = if orderToMatch.action is "buy" then math.multiply(matchedAmount, MarketHelper.fromBigint(orderToMatch.unit_price)) else matchedAmount
        changeBalance = if orderToMatch.action is "buy" then math.add(holdBalance, -math.multiply(matchedAmount, MarketHelper.fromBigint(unitPrice))) else 0
        sellWallet.addHoldBalance -holdBalance, transaction, (err, sellWallet)->
          return callback err  if err or not sellWallet
          sellWallet.addBalance changeBalance, transaction, (err, sellWallet)->
            return callback err  if err or not sellWallet
            buyWallet.addBalance resultAmount, transaction, (err, buyWallet)->
              return callback err  if err or not buyWallet
              orderToMatch.updateFromMatchedData matchData, transaction, (err, updatedOrder)->
                console.error "Could not process order ", err  if err
                return callback err  if err
                OrderLog.logMatch matchData, transaction, (err, orderLog)->
                  console.error "Could not save order log ", err  if err
                  return callback err  if err
                  callback null, updatedOrder, orderLog
                  TradeHelper.pushUserUpdate
                    type: "wallet-balance-changed"
                    user_id: sellWallet.user_id
                    eventData: JsonRenderer.wallet sellWallet
                  TradeHelper.pushUserUpdate
                    type: "wallet-balance-changed"
                    user_id: buyWallet.user_id
                    eventData: JsonRenderer.wallet buyWallet

  trackMatchedOrder: (orderLog, callback = ()->)->
    eventType = if orderLog.status is "completed" then "order-completed" else "order-partially-completed"
    MarketStats.trackFromOrderLog orderLog, (err, mkSt)->
      callback err, mkSt
      TradeHelper.pushOrderUpdate
        type: "market-stats-updated"
        eventData: mkSt.toJSON()
    orderLog.getOrder().complete (err, order)->
      TradeHelper.pushOrderUpdate
        type: eventType
        eventData: JsonRenderer.order order

exports = module.exports = TradeHelper