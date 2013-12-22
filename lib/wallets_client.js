(function() {
  var WalletsClient, exports, request;

  request = require("request");

  WalletsClient = (function() {
    WalletsClient.prototype.host = null;

    WalletsClient.prototype.commands = {
      "create_account": "post"
    };

    function WalletsClient(options) {
      if (options == null) {
        options = {};
      }
      if (options.host) {
        this.host = options.host;
      }
    }

    WalletsClient.prototype.send = function(command, data, callback) {
      var param, url, _i, _len;
      if (callback == null) {
        callback = function() {};
      }
      url = "http://" + this.host + "/" + command;
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        param = data[_i];
        url += "/" + param;
      }
      if (this.commands[command]) {
        return request[this.commands[command]](url, {
          json: true
        }, callback);
      } else {
        return callback("Invalid command '" + command + "'");
      }
    };

    return WalletsClient;

  })();

  exports = module.exports = WalletsClient;

}).call(this);
