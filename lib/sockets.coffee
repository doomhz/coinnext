io = require "socket.io"
Chat = require "../models/chat"
_s = require "underscore.string"

sockets = {}

initSockets = (server, env)->
  ioOptions =
    log: if env is "production" then false else false
  
  sockets.io = io.listen server, ioOptions

  sockets.usersSocket = sockets.io.of("/users").on "connection", (socket)->
    socket.on "listen", (data)->
      socket.user_id = data.id
    socket.on "external-event", (data)->
      try
        for sId, so of sockets.usersSocket.sockets
          so.emit data.type, data.eventData  if so.user_id is data.user_id
      catch e
        console.error "Could not emit to socket namespace /users #{userId}: #{e}"
      return

    setInterval ()->
        for sId, so of sockets.usersSocket.sockets
          so.emit "test-user", {a:1}
      , 3000
  
  sockets.ordersSocket = sockets.io.of("/orders").on "connection", (socket)->
    socket.on "external-event", (data)->
      try
        for sId, so of sockets.ordersSocket.sockets
          so.emit data.type, data.eventData
      catch e
        console.error "Could not emit to socket namespace /orders: #{e}"
      return

    setInterval ()->
        for sId, so of sockets.ordersSocket.sockets
          so.emit "test-order", {a:1}
      , 3000

  sockets.chatSocket = sockets.io.of("/chat").on "connection", (socket)->
    socket.on "join", (data)->
      socket.join data.room
    socket.on "add-message", (data)->
      data.message = _s.truncate _s.trim(data.message), 150
      if data.message.length
        message = new Chat data
        message.save()
        sockets.chatSocket.in(data.room).emit "new-message", message
      return
    socket.on "disconnect", (data)->
      for roomNamespace, val of sockets.io.sockets.manager.roomClients[socket.id]
        roomName = if roomNamespace.indexOf("/chat/") > -1 then roomNamespace.replace("/chat/", "") else false
        if roomName
          socket.leave roomName
      return

    setInterval ()->
        for sId, so of sockets.chatSocket.sockets
          so.emit "test-chat", {a:1}
      , 3000

  sockets

exports = module.exports = initSockets