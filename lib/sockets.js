(function() {
  var Chat, exports, initSockets, io, sockets, _s;

  io = require("socket.io");

  _s = require("underscore.string");

  Chat = GLOBAL.db.Chat;

  sockets = {};

  initSockets = function(server, env) {
    var ioOptions;
    ioOptions = {
      log: env === "production" ? false : false
    };
    sockets.io = io.listen(server, ioOptions);
    sockets.io.configure("production", function() {
      sockets.io.enable("browser client minification");
      sockets.io.enable("browser client etag");
      return sockets.io.enable("browser client gzip");
    });
    sockets.usersSocket = sockets.io.of("/users").on("connection", function(socket) {
      socket.on("listen", function(data) {
        return socket.user_id = data.id;
      });
      return socket.on("external-event", function(data) {
        var e, sId, so, _ref;
        try {
          _ref = sockets.usersSocket.sockets;
          for (sId in _ref) {
            so = _ref[sId];
            if (so.user_id === data.user_id) {
              so.emit(data.type, data.eventData);
            }
          }
        } catch (_error) {
          e = _error;
          console.error("Could not emit to socket namespace /users " + userId + ": " + e);
        }
        return this;
      });
    });
    sockets.ordersSocket = sockets.io.of("/orders").on("connection", function(socket) {
      return socket.on("external-event", function(data) {
        var e, sId, so, _ref;
        try {
          _ref = sockets.ordersSocket.sockets;
          for (sId in _ref) {
            so = _ref[sId];
            so.emit(data.type, data.eventData);
          }
        } catch (_error) {
          e = _error;
          console.error("Could not emit to socket namespace /orders: " + e);
        }
        return this;
      });
    });
    sockets.chatSocket = sockets.io.of("/chat").on("connection", function(socket) {
      socket.on("join", function(data) {
        return socket.join(data.room);
      });
      socket.on("add-message", function(data) {
        data.message = _s.truncate(_s.trim(data.message), 150);
        if (data.message.length) {
          Chat.create(data).success(function(message) {
            return sockets.chatSocket["in"](message.values.room).emit("new-message", message.values);
          });
        }
        return this;
      });
      return socket.on("disconnect", function(data) {
        var roomName, roomNamespace, val, _ref;
        _ref = sockets.io.sockets.manager.roomClients[socket.id];
        for (roomNamespace in _ref) {
          val = _ref[roomNamespace];
          roomName = roomNamespace.indexOf("/chat/") > -1 ? roomNamespace.replace("/chat/", "") : false;
          if (roomName) {
            socket.leave(roomName);
          }
        }
        return this;
      });
    });
    return sockets;
  };

  exports = module.exports = initSockets;

}).call(this);
