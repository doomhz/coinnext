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
      var clientSocket;
      clientSocket = ioClient.connect("" + this.host + "/" + this.path);
      return clientSocket.on("connect", function(s) {
        clientSocket.emit("external-event", data);
        return clientSocket.socket.disconnect();
      });
    };

    return ClientSocket;

  })();

  exports = module.exports = ClientSocket;

}).call(this);
