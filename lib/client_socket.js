(function() {
  var ClientSocket, exports, ioClient;

  ioClient = require("socket.io-client");

  ClientSocket = (function() {
    ClientSocket.prototype.host = "http://localhost:5000";

    ClientSocket.prototype.path = "users";

    function ClientSocket(options) {
      if (options == null) {
        options = {};
      }
      if (options.host) {
        this.host = options.host;
      }
      if (options.path) {
        this.path = options.path;
      }
    }

    ClientSocket.prototype.send = function(data) {
      if (!this.socket) {
        this.socket = ioClient.connect("" + this.host + "/" + this.path);
        return this.socket.on("connect", (function(_this) {
          return function(s) {
            return _this.socket.emit("external-event", data);
          };
        })(this));
      } else {
        return this.socket.emit("external-event", data);
      }
    };

    ClientSocket.prototype.close = function() {
      var e;
      try {
        return this.socket.socket.disconnect();
      } catch (_error) {
        e = _error;
        return console.error("Could not close client socket " + this.path, e);
      }
    };

    return ClientSocket;

  })();

  exports = module.exports = ClientSocket;

}).call(this);
