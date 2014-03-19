(function() {
  var Chat, JsonRenderer;

  Chat = GLOBAL.db.Chat;

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    return app.get("/chat/messages", function(req, res) {
      return Chat.findLastMessages(function(err, messages) {
        res.setHeader("Access-Control-Allow-Origin", "*");
        return res.json(JsonRenderer.chatMessages(messages));
      });
    });
  };

}).call(this);
