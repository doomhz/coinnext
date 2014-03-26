restify = require "restify"
Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
TradeQueue = require "../../lib/trade_queue"
trader = null
JsonRenderer = require "../../lib/json_renderer"
MarketHelper = require "../../lib/market_helper"
ClientSocket = require "../../lib/client_socket"
orderSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "orders"

module.exports = (app)->

  app.post "/publish_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    console.log orderId
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err
      return next(new restify.ConflictError "Trade queue down")  if not trader
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
      trader.publishOrder queueData, (queueError, response)->
        console.log arguments
      order.published = true
      order.save().complete (err, order)->
        return next(new restify.ConflictError err)  if err
        res.send
          id:        orderId
          published: true
        orderSocket.send
          type: "order-published"
          eventData: JsonRenderer.order order

  app.del "/cancel_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    console.log orderId
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err
      return next(new restify.ConflictError "Trade queue down")  if not trader
      queueData =
        eventType: "event"
        data:
          action: "cancelOrder"
          orderId: order.id
      trader.publishOrder queueData, (queueError, response)->
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
                orderSocket.send
                  type: "order-canceled"
                  eventData:
                    id: orderId
              transaction.done (err)->
                next(new restify.ConflictError "Could not cancel order #{orderId} - #{err}")

  # TODO: Move to a separate component
  onOrderCompleted = (message)->
    #console.log "incoming result ", message
    result = null
    try
      result = JSON.parse(message.data.toString())
    #console.log result
    if result and result.eventType is "orderResult"
      orderId = result.data.orderId
      status = result.data.orderState
      soldAmount = MarketHelper.convertFromBigint result.data.soldAmount
      receivedAmount = MarketHelper.convertFromBigint result.data.receivedAmount
      fee = MarketHelper.convertFromBigint result.data.orderFee
      unitPrice = MarketHelper.convertFromBigint result.data.orderPPU
      Order.findById orderId, (err, order)->
        return console.error "Wrong order to complete ", result  if not order
        Wallet.findUserWalletByCurrency order.user_id, order.buy_currency, (err, buyWallet)->
          Wallet.findUserWalletByCurrency order.user_id, order.sell_currency, (err, sellWallet)->
            GLOBAL.db.sequelize.transaction (transaction)->
              sellWallet.addHoldBalance -soldAmount, transaction, (err, sellWallet)->
                if err or not sellWallet
                  return transaction.rollback().success ()->
                    next(new restify.ConflictError "Could not complete order #{orderId} - #{err}")
                buyWallet.addBalance receivedAmount, transaction, (err, buyWallet)->
                  if err or not buyWallet
                    return transaction.rollback().success ()->
                      next(new restify.ConflictError "Could not complete order #{orderId} - #{err}")
                  order.status = status
                  order.sold_amount += soldAmount
                  order.result_amount += receivedAmount
                  order.fee = fee
                  order.unit_price = unitPrice
                  order.close_time = Date.now()  if status is "completed"
                  order.save({transaction: transaction}).complete (err, order)->
                    return console.error "Could not process order ", result, err  if err
                    if err
                      return transaction.rollback().success ()->
                        next(new restify.ConflictError "Could not process order #{orderId} - #{err}")
                    transaction.commit().success ()->
                      if order.status is "completed"
                        MarketStats.trackFromOrder order, (err, mkSt)->
                          orderSocket.send
                            type: "market-stats-updated"
                            eventData: mkSt.toJSON()
                        orderSocket.send
                          type: "order-completed"
                          eventData: JsonRenderer.order order
                      if order.status is "partiallyCompleted"
                        orderSocket.send
                          type: "order-partially-completed"
                          eventData: JsonRenderer.order order
                      console.log "Processed order #{order.id} ", result          
                    transaction.done (err)->
                      next(new restify.ConflictError "Could not process order #{orderId} - #{err}")


  tq = new TradeQueue
    connection:               GLOBAL.appConfig().amqp.connection
    openOrdersQueueName:      GLOBAL.appConfig().amqp.queues.open_orders
    completedOrdersQueueName: GLOBAL.appConfig().amqp.queues.completed_orders
    onComplete:               onOrderCompleted
    onConnect:                (tradeQueue)->
      trader = tradeQueue
  tq.connect()
