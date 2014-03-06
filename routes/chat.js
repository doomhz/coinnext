(function() {
  var Chat;

  Chat = GLOBAL.db.Chat;

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
