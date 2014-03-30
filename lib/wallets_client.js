(function() {
  var WalletsClient, exports, request;

  request = require("request");

  WalletsClient = (function() {
    WalletsClient.prototype.host = null;

    WalletsClient.prototype.commands = {
      "create_account": "post",
      "publish_order": "post",
      "cancel_order": "del",
      "process_payment": "post",
      "wallet_balance": "get",
      "wallet_info": "get"
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
      var e, param, url, _i, _len;
      if (callback == null) {
        callback = function() {};
      }
      url = "http://" + this.host + "/" + command;
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        param = data[_i];
        url += "/" + param;
      }
      if (this.commands[command]) {
        try {
          return request[this.commands[command]](url, {
            json: true
          }, callback);
        } catch (_error) {
          e = _error;
          console.error(e);
          return callback("Bad response '" + e + "'");
        }
      } else {
        return callback("Invalid command '" + command + "'");
      }
    };

    return WalletsClient;

  })();

  exports = module.exports = WalletsClient;

}).call(this);
