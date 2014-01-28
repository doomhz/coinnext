(function() {
  var Chat;

  Chat = require("../models/chat");

  module.exports = function(app) {
    return app.get("/chat/messages/:room", function(req, res) {
      var room;
      room = req.params.room;
      return Chat.findMessagesByRoom(room, function(err, messages) {
        res.setHeader("Access-Control-Allow-Origin", "*");
        return res.json(messages);
      });
    });
  };

}).call(this);
