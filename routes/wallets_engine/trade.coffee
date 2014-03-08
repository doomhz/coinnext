restify = require "restify"
Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
TradeQueue = require "../../lib/trade_queue"
trader = null
JsonRenderer = require "../../lib/json_renderer"
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
      amount = order.amount * 100000000
      unitPrice = if order.unit_price then order.unit_price * 100000000 else order.unit_price
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
        wallet.holdBalance -remainingHoldBalance, (err, wallet)->
          order.destroy().complete (err)->
            return next(new restify.ConflictError err)  if err
            res.send
              id:        orderId
              canceled: true
            orderSocket.send
              type: "order-canceled"
              eventData:
                id: orderId


  onOrderCompleted = (message)->
    #console.log "incoming result ", message
    result = null
    try
      result = JSON.parse(message.data.toString())
    #console.log result
    if result and result.eventType is "orderResult"
      orderId = result.data.orderId
      status = result.data.orderState
      soldAmount = parseFloat(result.data.soldAmount) / 100000000
      receivedAmount = parseFloat(result.data.receivedAmount) / 100000000
      fee = parseFloat(result.data.orderFee) / 100000000
      unitPrice = parseFloat(result.data.orderPPU) / 100000000
      Order.findById orderId, (err, order)->
        return console.error "Wrong order to complete ", result  if not order
        Wallet.findUserWalletByCurrency order.user_id, order.buy_currency, (err, buyWallet)->
          Wallet.findUserWalletByCurrency order.user_id, order.sell_currency, (err, sellWallet)->
            sellWallet.addHoldBalance -soldAmount, (err, sellWallet)->
              buyWallet.addBalance receivedAmount, (err, buyWallet)->
                order.status = status
                order.sold_amount += soldAmount
                order.result_amount += receivedAmount
                order.fee = fee
                order.unit_price = unitPrice
                order.close_time = Date.now()  if status is "completed"
                order.save().complete (err, order)->
                  return console.error "Could not process order ", result, err  if err
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


  tq = new TradeQueue
    connection:               GLOBAL.appConfig().amqp.connection
    openOrdersQueueName:      GLOBAL.appConfig().amqp.queues.open_orders
    completedOrdersQueueName: GLOBAL.appConfig().amqp.queues.completed_orders
    onComplete:               onOrderCompleted
    onConnect:                (tradeQueue)->
      trader = tradeQueue
  tq.connect()
