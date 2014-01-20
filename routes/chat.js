(function() {
  var Chat, _s;

  Chat = require("../models/chat");

  _s = require("underscore.string");

  module.exports = function(app) {
    app.get("/chat/messages/:room", function(req, res) {
      var room;
      room = req.params.room;
      return Chat.findMessagesByRoom(room, function(err, messages) {
        res.setHeader("Access-Control-Allow-Origin", "*");
        return res.json(messages);
      });
    });
    return GLOBAL.chatSocket = GLOBAL.io.of("/chat").on("connection", function(socket) {
      socket.on("join", function(data) {
        return socket.join(data.room);
      });
      socket.on("add-message", function(data) {
        var message;
        data.message = _s.truncate(_s.trim(data.message), 150);
        if (data.message.length) {
          message = new Chat(data);
          message.save();
          return GLOBAL.chatSocket["in"](data.room).emit("new-message", message);
        }
      });
      return socket.on("disconnect", function(data) {
        var roomName, roomNamespace, val, _ref, _results;
        _ref = io.sockets.manager.roomClients[socket.id];
        _results = [];
        for (roomNamespace in _ref) {
          val = _ref[roomNamespace];
          roomName = roomNamespace.indexOf("/chat/") > -1 ? roomNamespace.replace("/chat/", "") : false;
          if (roomName) {
            _results.push(socket.leave(roomName));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
    });
  };

}).call(this);
