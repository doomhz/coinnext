Chat = require "../models/chat"
_s = require "underscore.string"

module.exports = (app)->

  app.get "/chat/messages/:room", (req, res)->
    room = req.params.room
    Chat.findMessagesByRoom room, (err, messages)->
      res.setHeader "Access-Control-Allow-Origin", "*"
      res.json messages

  GLOBAL.chatSocket = GLOBAL.io.of("/chat").on "connection", (socket)->
    socket.on "join", (data)->
      socket.join data.room
    socket.on "add-message", (data)->
      data.message = _s.truncate _s.trim(data.message), 150
      if data.message.length
        message = new Chat data
        message.save()
        GLOBAL.chatSocket.in(data.room).emit "new-message", message
    socket.on "disconnect", (data)->
      for roomNamespace, val of io.sockets.manager.roomClients[socket.id]
        roomName = if roomNamespace.indexOf("/chat/") > -1 then roomNamespace.replace("/chat/", "") else false
        if roomName
          socket.leave roomName
