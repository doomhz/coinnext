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
        findLastUserMessage: function(userId, callback) {
          var query;
          query = {
            where: {
              user_id: userId
            },
            order: [["created_at", "DESC"]],
            limit: 1
          };
          return Chat.find(query).complete(callback);
        },
        getGlobalRoomName: function() {
          return GLOBAL_ROOM_NAME;
        },
        addMessage: function(data, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return Chat.findLastUserMessage(data.user_id, function(err, message) {
            if (message && message.isSpam(data)) {
              return callback("Dropping spam message " + data.message + " by user " + data.user_id + ".");
            }
            return Chat.create(data).complete(callback);
          });
        }
      },
      instanceMethods: {
        isSpam: function(newMessage) {
          return this.isTooEarly() || this.isDuplicate(newMessage);
        },
        isDuplicate: function(newMessage) {
          return this.message === newMessage.message;
        },
        isTooEarly: function() {
          var twoSecondsAgo;
          twoSecondsAgo = new Date(Date.now() - 2 * 1000);
          return this.created_at >= twoSecondsAgo;
        }
      }
    });
    return Chat;
  };

}).call(this);
