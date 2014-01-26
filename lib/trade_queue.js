(function() {
  var TradeQueue, amqp, exports;

  amqp = require("amqp");

  TradeQueue = (function() {
    TradeQueue.prototype.connectionData = null;

    TradeQueue.prototype.openOrdersQueueName = null;

    TradeQueue.prototype.completedOrdersQueueName = null;

    TradeQueue.prototype.connection = null;

    TradeQueue.prototype.exchange = null;

    function TradeQueue(options) {
      this.connectionData = options.connection;
      this.openOrdersQueueName = options.openOrdersQueueName;
      this.completedOrdersQueueName = options.completedOrdersQueueName;
      this.onConnect = options.onConnect;
      this.onComplete = options.onComplete;
    }

    TradeQueue.prototype.connect = function() {
      var _this = this;
      this.connection = amqp.createConnection(this.connectionData);
      this.connection.on("ready", function() {
        return _this.connection.queue(_this.openOrdersQueueName, function(openOrdersQueue) {
          return _this.connection.queue(_this.completedOrdersQueueName, function(completedOrdersQueue) {
            completedOrdersQueue.bind("#");
            completedOrdersQueue.subscribe(_this.onComplete);
            if (_this.onConnect) {
              return _this.onConnect(_this);
            }
          });
        });
      });
      return this.connection.on("error", function() {
        return console.error(arguments);
      });
    };

    TradeQueue.prototype.publishOrder = function(body, callback) {
      return this.connection.publish(this.openOrdersQueueName, body, null, callback);
    };

    return TradeQueue;

  })();

  exports = module.exports = TradeQueue;

}).call(this);
