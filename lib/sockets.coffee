io = require "socket.io"
SessionSockets = require "session.socket.io"
redis = require "redis"
SocketsRedisStore = require "socket.io/lib/stores/redis"
socketPub = redis.createClient GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {auth_pass: GLOBAL.appConfig().redis.pass}
socketSub = redis.createClient GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {auth_pass: GLOBAL.appConfig().redis.pass}
socketClient = redis.createClient GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {auth_pass: GLOBAL.appConfig().redis.pass}
externalEventsSub = redis.createClient GLOBAL.appConfig().redis.port, GLOBAL.appConfig().redis.host, {auth_pass: GLOBAL.appConfig().redis.pass}

Chat = GLOBAL.db.Chat
JsonRenderer = require "./json_renderer"

sockets = {}

initSockets = (server, env, sessionStore, cookieParser)->
  ioOptions =
    log: if env is "production" then false else false
  
  sockets.io = io.listen server, ioOptions

  sockets.io.configure "production", ()->
    sockets.io.enable "browser client minification"
    sockets.io.enable "browser client etag"
    sockets.io.enable "browser client gzip"
    sockets.io.set "origins", "#{GLOBAL.appConfig().users.hostname}:*"

  sockets.io.set "store", new SocketsRedisStore
    redis: redis
    redisPub: socketPub
    redisSub: socketSub
    redisClient: socketClient

  externalEventsSub.subscribe "external-events"
  externalEventsSub.on "message", (channel, data)->
    if channel is "external-events"
      try
        data = JSON.parse data
        if data.namespace is "users"
          for sId, so of sockets.io.of("/users").sockets
            so.emit data.type, data.eventData  if so.user_id is data.user_id
        if data.namespace is "orders"
          sockets.io.of("/orders").emit data.type, data.eventData
      catch e
        console.error "Could not emit to socket #{data}: #{e}"
      @

  sockets.sessionSockets = new SessionSockets sockets.io, sessionStore, cookieParser, GLOBAL.appConfig().session.session_key

  sockets.sessionSockets.of("/users").on "connection", (err, socket, session)->
    socket.user_id = session.passport.user  if session and session.passport
  
  sockets.io.of("/orders").on "connection", (socket)->

  sockets.sessionSockets.of("/chat").on "connection", (err, socket, session)->
    socket.user_id = session.passport.user  if session and session.passport
    socket.on "add-message", (data)->
      return  if not socket.user_id
      data.user_id = socket.user_id
      Chat.addMessage data, (err, message)->
        return console.error err  if err
        message.getUser().success (user)->
          sockets.io.of("/chat").emit "new-message", JsonRenderer.chatMessage message, user
      @

  sockets

exports = module.exports = initSockets