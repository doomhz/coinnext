_s = require "underscore.string"

module.exports = (sequelize, DataTypes) ->
  
  MESSAGES_LIMIT = 10000
  GLOBAL_ROOM_NAME = "global"

  Chat = sequelize.define "Chat",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      message:
        type: DataTypes.TEXT
        allowNull: false
        len: [1, 150]
        set: (message)->
          @setDataValue "message", _s.truncate _s.trim(message), 150
    ,
      tableName: "chats"
      classMethods:
        findLastMessages: (callback)->
          oneDayAgo = new Date (Date.now() - 24*60*60*1000)
          query = 
            where: 
              created_at: 
                gt: oneDayAgo
            order: [
              ["created_at", "DESC"]
            ]
            limit: MESSAGES_LIMIT
            include: [
              {model: GLOBAL.db.User, attributes: ["username"]}
            ]
          Chat.findAll(query).complete callback

        getGlobalRoomName: ()->
          GLOBAL_ROOM_NAME

  Chat