Chat = GLOBAL.db.Chat
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.get "/chat/messages", (req, res)->
    Chat.findLastMessages (err, messages)->
      res.setHeader "Access-Control-Allow-Origin", "*"
      res.json JsonRenderer.chatMessages messages
