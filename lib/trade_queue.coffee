amqp = require "amqp"

class TradeQueue

  connectionData: null
  
  openOrdersQueueName: null
  
  completedOrdersQueueName: null
  
  connection: null

  exchange: null

  constructor: (options)->
    @connectionData = options.connection
    @openOrdersQueueName = options.openOrdersQueueName
    @completedOrdersQueueName = options.completedOrdersQueueName
    @onConnect = options.onConnect
    @onComplete = options.onComplete

  connect: ()->
    @connection = amqp.createConnection @connectionData
    @connection.on "ready", ()=>
      @connection.queue @openOrdersQueueName, (openOrdersQueue)=>
        @connection.queue @completedOrdersQueueName, (completedOrdersQueue)=>
          completedOrdersQueue.bind "#"
          completedOrdersQueue.subscribe @onComplete
          @onConnect @  if @onConnect
    @connection.on "error", ()=>
      console.error arguments

  publishOrder: (body, callback)->
    @connection.publish @openOrdersQueueName, body, null, callback

exports = module.exports = TradeQueue