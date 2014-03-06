Chat = GLOBAL.db.Chat

module.exports = (app)->

  app.get "/chat/messages/:room", (req, res)->
    room = req.params.room
    Chat.findMessagesByRoom room, (err, messages)->
      res.setHeader "Access-Control-Allow-Origin", "*"
      res.json messages
