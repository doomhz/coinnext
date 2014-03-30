restify = require "restify"
Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
TradeHelper = require "../../lib/trade_helper"
JsonRenderer = require "../../lib/json_renderer"
MarketHelper = require "../../lib/market_helper"

module.exports = (app)->

  app.post "/publish_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    console.log orderId
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err
      return next(new restify.ConflictError "Trade queue down")  if not TradeHelper.trader
      marketType = "#{order.action}_#{order.type}".toUpperCase()
      orderCurrency = order["#{order.action}_currency"]
      amount = MarketHelper.convertToBigint order.amount
      unitPrice = if order.unit_price then MarketHelper.convertToBigint order.unit_price else order.unit_price
      queueData =
        eventType: "order"
        data:
          orderId: order.id
          orderType: marketType #BUY_MARKET, SELL_MARKET, BUY_LIMIT, SELL_LIMIT
          orderAmount: amount
          orderCurrency: orderCurrency
          orderLimitPrice: unitPrice
      TradeHelper.trader.publishOrder queueData, (queueError, response)->
        console.log arguments
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
    console.log orderId
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err
      return next(new restify.ConflictError "Trade queue down")  if not TradeHelper.trader
      queueData =
        eventType: "event"
        data:
          action: "cancelOrder"
          orderId: order.id
      TradeHelper.trader.publishOrder queueData, (queueError, response)->
        console.log arguments
      Wallet.findUserWalletByCurrency order.user_id, order.sell_currency, (err, wallet)->
        remainingHoldBalance = order.amount - order.sold_amount
        GLOBAL.db.sequelize.transaction (transaction)->
          wallet.holdBalance -remainingHoldBalance, transaction, (err, wallet)->
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
                next(new restify.ConflictError "Could not cancel order #{orderId} - #{err}")

  TradeHelper.initQueue()
