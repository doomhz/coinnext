(function() {
  var ClientSocket, exports, redis;

  redis = require("redis");

  ClientSocket = (function() {
    ClientSocket.prototype.namespace = "users";

    ClientSocket.prototype.pub = null;

    function ClientSocket(options) {
      if (options == null) {
        options = {};
      }
      if (options.namespace) {
        this.namespace = options.namespace;
      }
      this.pub = redis.createClient(options.redis.port, options.redis.host);
    }

    ClientSocket.prototype.send = function(data) {
      data.namespace = this.namespace;
      return this.pub.publish("external-events", JSON.stringify(data));
    };

    ClientSocket.prototype.close = function() {
      var e;
      try {
        if (this.pub) {
          return this.pub.disconnect();
        }
      } catch (_error) {
        e = _error;
        return console.error("Could not close Pub connection " + this.namespace, e);
      }
    };

    return ClientSocket;

  })();

  exports = module.exports = ClientSocket;

}).call(this);
