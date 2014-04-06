restify = require "restify"
Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
TradeHelper = require "../../lib/trade_helper"
JsonRenderer = require "../../lib/json_renderer"
MarketHelper = require "../../lib/market_helper"

module.exports = (app)->

  app.post "/publish_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    #console.log orderId
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err
      orderCurrency = order["#{order.action}_currency"]
      MarketStats.findEnabledMarket orderCurrency, "BTC", (err, market)->
        return next(new restify.ConflictError "#{new Date()} - Will not process order #{orderId}, the market for #{orderCurrency} is disabled.")  if not market
        TradeHelper.submitOrder order, (err)->
          return next(new restify.ConflictError err)  if err
          order.published = true
          order.save().complete (err, order)->
            return next(new restify.ConflictError err)  if err
            res.send
              id:        orderId
              published: true
            TradeHelper.pushOrderUpdate
              type: "order-published"
              eventData: JsonRenderer.order order

  app.del "/cancel_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    #console.log orderId
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err or not order
      orderCurrency = order["#{order.action}_currency"]
      MarketStats.findEnabledMarket orderCurrency, "BTC", (err, market)->
        return next(new restify.ConflictError "#{new Date()} - Will not process order #{orderId}, the market for #{orderCurrency} is disabled.")  if not market
        TradeHelper.cancelOrder order, (err)->
          return next(new restify.ConflictError err)  if err
          Wallet.findUserWalletByCurrency order.user_id, order.sell_currency, (err, wallet)->
            GLOBAL.db.sequelize.transaction (transaction)->
              wallet.holdBalance -order.left_hold_balance, transaction, (err, wallet)->
                if err or not wallet
                  return transaction.rollback().success ()->
                    next(new restify.ConflictError "Could not cancel order #{orderId} - #{err}")
                order.destroy({transaction: transaction}).complete (err)->
                  if err
                    return transaction.rollback().success ()->
                      next(new restify.ConflictError err)
                  transaction.commit().success ()->
                    res.send
                      id:       orderId
                      canceled: true
                    TradeHelper.pushOrderUpdate
                      type: "order-canceled"
                      eventData:
                        id: orderId
                  transaction.done (err)->
                    next(new restify.ConflictError "Could not cancel order #{orderId} - #{err}")  if err

  app.post "/orders_match", (req, res, next)->
    matchedData = req.body
    Order.findById matchedData[0].order_id, (err, orderToMatch)->
      return next(new restify.ConflictError "Wrong order to complete #{matchedData[0].order_id} - #{err}")  if not orderToMatch or err
      Order.findById matchedData[1].order_id, (err, matchingOrder)->
        return next(new restify.ConflictError "Wrong order to complete #{matchedData[1].order_id} - #{err}")  if not matchingOrder or err
        GLOBAL.db.sequelize.transaction (transaction)->
          TradeHelper.updateMatchedOrder orderToMatch, matchedData[0], transaction, (err, updatedOrderToMatch)->
            if err
              console.error "Could not process order #{orderToMatch.id}", err
              return transaction.rollback().success ()->
                next(new restify.ConflictError "Could not process order #{orderToMatch.id} - #{err}")
            TradeHelper.updateMatchedOrder matchingOrder, matchedData[1], transaction, (err, updatedMatchingOrder)->
              if err
                console.error "Could not process order #{matchingOrder.id}", err
                return transaction.rollback().success ()->
                  next(new restify.ConflictError "Could not process order #{matchingOrder.id} - #{err}")
              transaction.commit().success ()->
                TradeHelper.trackMatchedOrder updatedOrderToMatch
                TradeHelper.trackMatchedOrder updatedMatchingOrder
                res.send()
              transaction.done (err)->
                next(new restify.ConflictError "Could not process order #{orderId} - #{err}")  if err
