Order = GLOBAL.db.Order
OrderLog = GLOBAL.db.OrderLog
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
MarketHelper = require "./market_helper"
JsonRenderer = require "./json_renderer"
MarketHelper = require "./market_helper"
ClientSocket = require "./client_socket"
orderSocket = new ClientSocket
  namespace: "orders"
  redis: GLOBAL.appConfig().redis
usersSocket = new ClientSocket
  namespace: "users"
  redis: GLOBAL.appConfig().redis
math = require "./math"

TradeHelper =

  createOrder: (data, callback = ()->)->
    holdBalance = MarketHelper.multiplyBigints data.amount, data.unit_price  if data.type is "limit" and data.action is "buy"
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
                MarketStats.trackFromNewOrder newOrder
                TradeHelper.pushUserUpdate
                  type: "wallet-balance-changed"
                  user_id: wallet.user_id
                  eventData: JsonRenderer.wallet wallet

  publishOrder: (orderId, callback)->
    Order.findById orderId, (err, order)->
      return callback "Could not publish order #{orderId} - #{err}"  if err
      return callback "Order #{orderId} not fund to be published"  if not order
      order.published = true
      order.in_queue = false
      order.save().complete (err, publishedOrder)->
        return callback "Could not save published order #{orderId} - #{err}"  if err
        callback err, publishedOrder
        TradeHelper.pushOrderUpdate
          type: "order-published"
          eventData: JsonRenderer.order publishedOrder

  cancelOrder: (orderId, callback = ()->)->
    Order.findById orderId, (err, order)->
      return callback "Could not find order to cancel #{orderId} - #{err}"  if err
      return callback "Could not find order to cancel #{orderId}"  if not order
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
                MarketStats.trackFromCancelledOrder order
                TradeHelper.pushOrderUpdate
                  type: "order-canceled"
                  eventData:
                    id: orderId
                TradeHelper.pushUserUpdate
                  type: "wallet-balance-changed"
                  user_id: wallet.user_id
                  eventData: JsonRenderer.wallet wallet

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
                  TradeHelper.trackMatchedOrder updatedMatchingOrderLog, ()->
                    MarketStats.trackFromMatchedOrder orderToMatch, matchingOrder
                    callback()

  updateMatchedOrder: (orderToMatch, matchData, transaction, callback)->
    Wallet.findUserWalletByCurrency orderToMatch.user_id, orderToMatch.buy_currency, (err, buyWallet)->
      Wallet.findUserWalletByCurrency orderToMatch.user_id, orderToMatch.sell_currency, (err, sellWallet)->
        matchedAmount = matchData.matched_amount
        resultAmount = matchData.result_amount
        unitPrice = matchData.unit_price
        holdBalance = if orderToMatch.action is "buy" then MarketHelper.multiplyBigints(matchedAmount, orderToMatch.unit_price) else matchedAmount
        changeBalance = if orderToMatch.action is "buy" then parseInt(math.subtract(MarketHelper.toBignum(holdBalance), MarketHelper.toBignum(MarketHelper.multiplyBigints(matchedAmount, unitPrice)))) else 0
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