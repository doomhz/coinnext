(function() {
  var Chat, JsonRenderer, SessionSockets, exports, initSockets, io, sockets;

  io = require("socket.io");

  SessionSockets = require("session.socket.io");

  Chat = GLOBAL.db.Chat;

  JsonRenderer = require("./json_renderer");

  sockets = {};

  initSockets = function(server, env, sessionStore, cookieParser) {
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
    sockets.sessionSockets = new SessionSockets(sockets.io, sessionStore, cookieParser, GLOBAL.appConfig().session.session_key);
    sockets.sessionSockets.of("/users").on("connection", function(err, socket, session) {
      if (session && session.passport) {
        socket.user_id = session.passport.user;
      }
      return socket.on("external-event", function(data) {
        var e, sId, so, _ref;
        try {
          _ref = sockets.io.of("/users").sockets;
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
    sockets.io.of("/orders").on("connection", function(socket) {
      return socket.on("external-event", function(data) {
        var e;
        try {
          sockets.io.of("/orders").emit(data.type, data.eventData);
        } catch (_error) {
          e = _error;
          console.error("Could not emit to socket namespace /orders: " + e);
        }
        return this;
      });
    });
    sockets.sessionSockets.of("/chat").on("connection", function(err, socket, session) {
      if (session && session.passport) {
        socket.user_id = session.passport.user;
      }
      return socket.on("add-message", function(data) {
        data.user_id = socket.user_id;
        Chat.create(data).success(function(message) {
          return message.getUser().success(function(user) {
            return sockets.io.of("/chat").emit("new-message", JsonRenderer.chatMessage(message, user));
          });
        });
        return this;
      });
    });
    return sockets;
  };

  exports = module.exports = initSockets;

}).call(this);
