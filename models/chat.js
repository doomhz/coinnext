(function() {
  var _s;

  _s = require("underscore.string");

  module.exports = function(sequelize, DataTypes) {
    var Chat, GLOBAL_ROOM_NAME, MESSAGES_LIMIT;
    MESSAGES_LIMIT = 10000;
    GLOBAL_ROOM_NAME = "global";
    Chat = sequelize.define("Chat", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      message: {
        type: DataTypes.TEXT,
        allowNull: false,
        len: [1, 150],
        set: function(message) {
          return this.setDataValue("message", _s.truncate(_s.trim(message), 150));
        }
      }
    }, {
      tableName: "chats",
      classMethods: {
        findLastMessages: function(callback) {
          var oneDayAgo, query;
          oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
          query = {
            where: {
              created_at: {
                gt: oneDayAgo
              }
            },
            order: [["created_at", "DESC"]],
            limit: MESSAGES_LIMIT,
            include: [
              {
                model: GLOBAL.db.User,
                attributes: ["username"]
              }
            ]
          };
          return Chat.findAll(query).complete(callback);
        },
        getGlobalRoomName: function() {
          return GLOBAL_ROOM_NAME;
        }
      }
    });
    return Chat;
  };

}).call(this);
