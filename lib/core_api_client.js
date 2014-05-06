(function() {
  var CoreAPIClient, exports, request;

  request = require("request");

  CoreAPIClient = (function() {
    CoreAPIClient.prototype.host = null;

    CoreAPIClient.prototype.commands = {
      "create_account": "post",
      "publish_order": "post",
      "cancel_order": "del",
      "create_payment": "post",
      "process_payment": "put",
      "cancel_payment": "del",
      "wallet_balance": "get",
      "wallet_info": "get"
    };

    function CoreAPIClient(options) {
      if (options == null) {
        options = {};
      }
      if (options.host) {
        this.host = options.host;
      }
    }

    CoreAPIClient.prototype.send = function(command, data, callback) {
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

    CoreAPIClient.prototype.sendWithData = function(command, data, callback) {
      var e, options, uri;
      if (callback == null) {
        callback = function() {};
      }
      uri = "http://" + this.host + "/" + command;
      if (this.commands[command]) {
        options = {
          uri: uri,
          method: this.commands[command],
          json: data
        };
        try {
          return request(options, callback);
        } catch (_error) {
          e = _error;
          console.error(e);
          return callback("Bad response " + e);
        }
      } else {
        return callback("Invalid command '" + command + "'");
      }
    };

    return CoreAPIClient;

  })();

  exports = module.exports = CoreAPIClient;

}).call(this);
