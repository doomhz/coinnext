crypto    = require "crypto"
speakeasy = require "speakeasy"
_         = require "underscore"

module.exports = (sequelize, DataTypes) ->

  UserToken = sequelize.define "UserToken",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      type:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        comment: "email_confirmation, google_auth, change_password"
        get: ()->
          MarketHelper.getTokenTypeLiteral @getDataValue("type")
        set: (type)->
          @setDataValue "type", MarketHelper.getTokenType(type)
      token:
        type: DataTypes.STRING(100)
        unique: true
    ,
      tableName: "user_tokens"
      classMethods:
        
        findByUserId: (userId, callback = ()->)->
          UserToken.find({where: {user_id: userId}}).complete callback

        findByToken: (token, callback = ()->)->
          UserToken.find({where: {token: token}}).complete callback

        generateGAuthPassByKey: (key)->
          speakeasy.time
            key: key
            encoding: "base32"

        isValidGAuthPassForKey: (pass, key)->
          UserToken.generateGAuthPassByKey(key) is pass

        generateGAuthData: ()->
          gData = speakeasy.generate_key
            name: "coinnext.com"
            length: 20
            google_auth_qr: true
          data =
            gauth_qr: gData.google_auth_qr
            gauth_key: gData.base32

        addGAuthTokenForUser: (key, userId, callback = ()->)->
          data =
            user_id: user_id
            type: "google_auth"
            token: key
          UserToken.findOrCreate({user_id: data.user_id, type: data.type}, data).complete (err, userToken, created)->
            return callback err, userToken  if created
            userToken.updateAttributes(data).complete callback
        
        dropGAuthDataForUser: (userId, callback = ()->)->
          UserToken.destroy({user_id: userId, type: "google_auth"}).complete callback

        generateChangePasswordToken: (seed, callback = ()->)->
          crypto.createHash("sha1").update("#{seed}#{GLOBAL.appConfig().salt}#{Date.now()}", "utf8").digest("hex")

  UserToken