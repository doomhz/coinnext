restify = require "restify"
Order = require "../../models/order"
Wallet = require "../../models/wallet"
TradeQueue = require "../../lib/trade_queue"

module.exports = (app)->

  trader = null

  app.post "/publish_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    console.log orderId
    Order.findById orderId, (err, order)->
      return next(new restify.ConflictError err)  if err
      return next(new restify.ConflictError "Trade queue down")  if not trader
      marketType = "#{order.action}_#{order.type}".toUpperCase()
      orderCurrency = order["#{order.action}_currency"]
      queueData =
        eventType: "order"
        eventUserId: order.user_id
        data:
          orderId: orderId
          orderType: marketType #BUY_MARKET, SELL_MARKET, BUY_LIMIT, SELL_LIMIT
          orderAmount: order.amount
          orderCurrency: orderCurrency
          orderLimitPrice: order.unit_price
      trader.publishOrder queueData, (queueError, response)->
        console.log arguments
      #if not queueError
      Order.update {_id: orderId}, {published: true}, (err, result)->
        if not err
          res.send
            id:        orderId
            published: true
        else
          return next(new restify.ConflictError err)
      #else
      #  return next(new restify.ConflictError "Trade queue error - #{queueError}")

  onOrderCompleted = (result)->
    # TODO: Confirm this with Charles
    if result.eventType is "orderResult"
      orderId = result.data.orderId
      status = result.data.orderState
      soldAmount = result.data.soldAmount
      receivedAmount = result.data.receivedAmount
      Order.findById orderId, (err, order)->
        if order
          Wallet.findUserWalletByCurrency order.user_id, order.buy_currency, (err, buyWallet)->
            Wallet.findUserWalletByCurrency order.user_id, order.sell_currency, (err, sellWallet)->
              sellWallet.holdBalance -soldAmount, (err, sellWallet)->
                buyWallet.addBalance receivedAmount, (err, buyWallet)->
                  Order.update {_id: orderId}, {status: status}, (err, res)->
                    console.error "Could not complete order #{result} - #{err}"  if err
        else
          console.error "Wrong order to complete - #{result}"


  tq = new TradeQueue
    connection:               GLOBAL.appConfig().amqp.connection
    openOrdersQueueName:      GLOBAL.appConfig().amqp.queues.open_orders
    completedOrdersQueueName: GLOBAL.appConfig().amqp.queues.completed_orders
    onComplete:               onOrderCompleted
    onConnect:                (tradeQueue)->
      trader = tradeQueue
  tq.connect()
