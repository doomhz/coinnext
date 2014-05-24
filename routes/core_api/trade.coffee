restify = require "restify"
Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
TradeHelper = require "../../lib/trade_helper"
JsonRenderer = require "../../lib/json_renderer"
MarketHelper = require "../../lib/market_helper"

module.exports = (app)->

  app.post "/publish_order", (req, res, next)->
    data = req.body
    orderCurrency = data["#{data.action}_currency"]
    MarketStats.findEnabledMarket orderCurrency, "BTC", (err, market)->
      return next(new restify.ConflictError "Market for #{orderCurrency} is disabled.")  if not market
      TradeHelper.createOrder data, (err, newOrder)->
        return next(new restify.ConflictError err)  if err
        TradeHelper.submitOrder newOrder, (err)->
          # TODO: Make a task that tries to resubmit non published orders...
          if err
            console.error "Could not publish the order #{newOrder.id} - #{err}"
            return res.send
              id:        newOrder.id
              published: false
          newOrder.published = true
          newOrder.save().complete (err, newOrder)->
            console.error "Could not set order #{newOrder.id} to published - #{err}"  if err
            res.send
              id:        newOrder.id
              published: newOrder.published
            TradeHelper.pushOrderUpdate
              type: "order-published"
              eventData: JsonRenderer.order newOrder

  app.del "/cancel_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err or not order or not order.canBeCanceled()
      orderCurrency = order["#{order.action}_currency"]
      MarketStats.findEnabledMarket orderCurrency, "BTC", (err, market)->
        return next(new restify.ConflictError "#{new Date()} - Will not process order #{orderId}, the market for #{orderCurrency} is disabled.")  if not market
        GLOBAL.db.sequelize.transaction (transaction)->
          GLOBAL.queue.Event.addCancelOrder {order_id: orderId}, (err)->
            if err
              return transaction.rollback().success ()->
                next(new restify.ConflictError "Could not cancel order #{orderId} - #{err}")
            order.in_queue = true
            order.save({transaction: transaction}).complete (err)->
              if err
                return transaction.rollback().success ()->
                  next(new restify.ConflictError "Could not set order #{orderId} for canceling - #{err}")
              transaction.commit().success ()->
                res.send
                  id: orderId
                TradeHelper.pushOrderUpdate
                  type: "order-to-cancel"
                  eventData:
                    id: orderId
