module.exports = (sequelize, DataTypes) ->
  
  MESSAGES_LIMIT = 10000

  Chat = sequelize.define "Chat",
      room:
        type: DataTypes.TEXT
        allowNull: false
      username:
        type: DataTypes.TEXT
        allowNull: false
      message:
        type: DataTypes.TEXT
        allowNull: false
    ,
      tableName: "chats"
      classMethods:
        findMessagesByRoom: (room, callback)->
          oneDayAgo = new Date (Date.now() - 24*60*60*1000)
          query = 
            where: 
              room: room
              created_at: 
                gt: oneDayAgo
            order: [
              ["created_at", "DESC"]
            ]
            limit: MESSAGES_LIMIT
          Chat.findAll(query).complete callback
  
  Chat