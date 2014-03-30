io = require "socket.io"
SessionSockets = require "session.socket.io"
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

  sockets.sessionSockets = new SessionSockets sockets.io, sessionStore, cookieParser, GLOBAL.appConfig().session.session_key

  sockets.sessionSockets.of("/users").on "connection", (err, socket, session)->
    socket.user_id = session.passport.user  if session and session.passport
    socket.on "external-event", (data)->
      try
        for sId, so of sockets.io.of("/users").sockets
          so.emit data.type, data.eventData  if so.user_id is data.user_id
      catch e
        console.error "Could not emit to socket namespace /users #{userId}: #{e}"
      @
  
  sockets.io.of("/orders").on "connection", (socket)->
    socket.on "external-event", (data)->
      try
        sockets.io.of("/orders").emit data.type, data.eventData
      catch e
        console.error "Could not emit to socket namespace /orders: #{e}"
      @

  sockets.sessionSockets.of("/chat").on "connection", (err, socket, session)->
    socket.user_id = session.passport.user  if session and session.passport
    socket.on "add-message", (data)->
      data.user_id = socket.user_id
      Chat.create(data).success (message)->
        message.getUser().success (user)->
          sockets.io.of("/chat").emit "new-message", JsonRenderer.chatMessage message, user
      @

  sockets

exports = module.exports = initSockets