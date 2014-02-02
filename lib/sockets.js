(function() {
  var Chat, exports, initSockets, io, sockets, _s;

  io = require("socket.io");

  Chat = require("../models/chat");

  _s = require("underscore.string");

  sockets = {};

  initSockets = function(server, env) {
    var ioOptions;
    ioOptions = {
      log: env === "production" ? false : false
    };
    sockets.io = io.listen(server, ioOptions);
    sockets.usersSocket = sockets.io.of("/users").on("connection", function(socket) {
      socket.on("listen", function(data) {
        return socket.user_id = data.id;
      });
      return socket.on("external-event", function(data) {
        var e, sId, _ref, _results;
        try {
          _ref = sockets.usersSocket.sockets;
          _results = [];
          for (sId in _ref) {
            socket = _ref[sId];
            if (socket.user_id === data.user_id) {
              _results.push(socket.emit(data.type, data.eventData));
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        } catch (_error) {
          e = _error;
          return console.error("Could not emit to socket namespace /users " + userId + ": " + e);
        }
      });
    });
    sockets.ordersSocket = sockets.io.of("/orders").on("connection", function(socket) {
      return socket.on("external-event", function(data) {
        var e, sId, _ref, _results;
        try {
          _ref = sockets.ordersSocket.sockets;
          _results = [];
          for (sId in _ref) {
            socket = _ref[sId];
            _results.push(socket.emit(data.type, data.eventData));
          }
          return _results;
        } catch (_error) {
          e = _error;
          return console.error("Could not emit to socket namespace /orders: " + e);
        }
      });
    });
    sockets.chatSocket = sockets.io.of("/chat").on("connection", function(socket) {
      socket.on("join", function(data) {
        return socket.join(data.room);
      });
      socket.on("add-message", function(data) {
        var message;
        data.message = _s.truncate(_s.trim(data.message), 150);
        if (data.message.length) {
          message = new Chat(data);
          message.save();
          return sockets.chatSocket["in"](data.room).emit("new-message", message);
        }
      });
      return socket.on("disconnect", function(data) {
        var roomName, roomNamespace, val, _ref, _results;
        _ref = sockets.io.sockets.manager.roomClients[socket.id];
        _results = [];
        for (roomNamespace in _ref) {
          val = _ref[roomNamespace];
          roomName = roomNamespace.indexOf("/chat/") > -1 ? roomNamespace.replace("/chat/", "") : false;
          if (roomName) {
            _results.push(socket.leave(roomName));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
    });
    return sockets;
  };

  exports = module.exports = initSockets;

}).call(this);
