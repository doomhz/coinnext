(function() {
  module.exports = function(sequelize, DataTypes) {
    var Chat, MESSAGES_LIMIT;
    MESSAGES_LIMIT = 10000;
    Chat = sequelize.define("Chat", {
      room: {
        type: DataTypes.TEXT,
        allowNull: false
      },
      username: {
        type: DataTypes.TEXT,
        allowNull: false
      },
      message: {
        type: DataTypes.TEXT,
        allowNull: false
      }
    }, {
      tableName: "chats",
      classMethods: {
        findMessagesByRoom: function(room, callback) {
          var oneDayAgo, query;
          oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
          query = {
            where: {
              room: room,
              created_at: {
                gt: oneDayAgo
              }
            },
            order: [["created_at", "DESC"]],
            limit: MESSAGES_LIMIT
          };
          return Chat.findAll(query).complete(callback);
        }
      }
    });
    return Chat;
  };

}).call(this);
