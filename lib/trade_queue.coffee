amqp = require "amqp"

class TradeQueue

  connectionData: null
  
  openOrdersQueueName: null
  
  completedOrdersQueueName: null
  
  connection: null

  exchange: null

  exchangeOptions:
    type: "direct"
    passive: false
    durable: true
    autoDelete: false

  queueOptions:
    pasive: false
    durable: true
    exclusive: false
    autoDelete: false

  constructor: (options)->
    @connectionData = options.connection
    @openOrdersQueueName = options.openOrdersQueueName
    @completedOrdersQueueName = options.completedOrdersQueueName
    @onConnect = options.onConnect
    @onComplete = options.onComplete

  connect: ()->
    @connection = amqp.createConnection @connectionData
    @connection.on "ready", ()=>
      console.log "queue connected"
      @exchange = @connection.exchange "coinx_exchange", @exchangeOptions
      @connection.queue @openOrdersQueueName, @queueOptions, (openOrdersQueue)=>
        openOrdersQueue.bind @exchange, "coinx_pending_indata"
        @connection.queue @completedOrdersQueueName, @queueOptions, (completedOrdersQueue)=>
          completedOrdersQueue.bind @exchange, "coinx_pending_outdata"
          completedOrdersQueue.subscribe @onComplete
          @onConnect @  if @onConnect
    @connection.on "error", ()=>
      console.error "queue error ", arguments

  publishOrder: (body, callback)->
    console.log "Publishing to queue ", body
    @exchange.publish "coinx_pending_indata", body, null, callback

exports = module.exports = TradeQueue