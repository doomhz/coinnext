Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
TradeQueue = require "./trade_queue"
JsonRenderer = require "./json_renderer"
MarketHelper = require "./market_helper"
ClientSocket = require "./client_socket"
orderSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "orders"

TradeHelper =

  trader: null

  pushOrderUpdate: (data)->
    orderSocket.send data

  initQueue: ()->
    tq = new TradeQueue
      connection:               GLOBAL.appConfig().amqp.connection
      openOrdersQueueName:      GLOBAL.appConfig().amqp.queues.open_orders
      completedOrdersQueueName: GLOBAL.appConfig().amqp.queues.completed_orders
      onComplete:               TradeHelper.onOrderCompleted
      onConnect:                (tradeQueue)->
        TradeHelper.trader = tradeQueue
    tq.connect()

  onOrderCompleted: (message)->
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

exports = module.exports = TradeHelper