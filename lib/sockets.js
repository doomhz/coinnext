(function() {
  var Chat, JsonRenderer, SessionSockets, SocketsRedisStore, exports, externalEventsSub, initSockets, io, redis, socketClient, socketPub, socketSub, sockets;

  io = require("socket.io");

  SessionSockets = require("session.socket.io");

  redis = require("redis");

  SocketsRedisStore = require("socket.io/lib/stores/redis");

  socketPub = redis.createClient(GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {
    auth_pass: GLOBAL.appConfig().redis.pass
  });

  socketSub = redis.createClient(GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {
    auth_pass: GLOBAL.appConfig().redis.pass
  });

  socketClient = redis.createClient(GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {
    auth_pass: GLOBAL.appConfig().redis.pass
  });

  externalEventsSub = redis.createClient(GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {
    auth_pass: GLOBAL.appConfig().redis.pass
  });

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
      sockets.io.enable("browser client gzip");
      return sockets.io.set("origins", "" + (GLOBAL.appConfig().users.hostname) + ":*");
    });
    sockets.io.set("store", new SocketsRedisStore({
      redis: redis,
      redisPub: socketPub,
      redisSub: socketSub,
      redisClient: socketClient
    }));
    externalEventsSub.subscribe("external-events");
    externalEventsSub.on("message", function(channel, data) {
      var e, sId, so, _ref;
      if (channel === "external-events") {
        try {
          data = JSON.parse(data);
          if (data.namespace === "users") {
            _ref = sockets.io.of("/users").sockets;
            for (sId in _ref) {
              so = _ref[sId];
              if (so.user_id === data.user_id) {
                so.emit(data.type, data.eventData);
              }
            }
          }
          if (data.namespace === "orders") {
            sockets.io.of("/orders").emit(data.type, data.eventData);
          }
        } catch (_error) {
          e = _error;
          console.error("Could not emit to socket " + data + ": " + e);
        }
        return this;
      }
    });
    sockets.sessionSockets = new SessionSockets(sockets.io, sessionStore, cookieParser, GLOBAL.appConfig().session.session_key);
    sockets.sessionSockets.of("/users").on("connection", function(err, socket, session) {
      if (session && session.passport) {
        return socket.user_id = session.passport.user;
      }
    });
    sockets.io.of("/orders").on("connection", function(socket) {});
    sockets.sessionSockets.of("/chat").on("connection", function(err, socket, session) {
      if (session && session.passport) {
        socket.user_id = session.passport.user;
      }
      return socket.on("add-message", function(data) {
        if (!socket.user_id) {
          return;
        }
        data.user_id = socket.user_id;
        Chat.addMessage(data, function(err, message) {
          if (err) {
            return console.error(err);
          }
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
