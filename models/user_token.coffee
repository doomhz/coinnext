MarketHelper = require "../lib/market_helper"
crypto    = require "crypto"
speakeasy = require "speakeasy"

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
        allowNull: false
    ,
      tableName: "user_tokens"
      classMethods:
        
        findByUser: (userId, callback = ()->)->
          UserToken.find({where: {user_id: userId}}).complete callback

        findByToken: (token, callback = ()->)->
          UserToken.find({where: {token: token}}).complete callback

        findByUserAndType: (userId, type, callback = ()->)->
          UserToken.find({where: {user_id: userId, type: MarketHelper.getTokenType(type)}}).complete callback

        generateGAuthPassByKey: (key)->
          speakeasy.time
            key: key
            encoding: "base32"

        isValidGAuthPassForKey: (pass, key)->
          UserToken.generateGAuthPassByKey(key) is pass

        isValidGAuthPassForUser: (userId, pass, callback)->
          UserToken.findByUserAndType userId, "google_auth", (err, googleToken)->
            callback err, UserToken.isValidGAuthPassForKey(pass, googleToken.token)

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
            user_id: userId
            type: "google_auth"
            token: key
          UserToken.findOrCreate({user_id: data.user_id, type: MarketHelper.getTokenType(data.type)}, data).complete (err, userToken, created)->
            return callback err, userToken  if created
            userToken.updateAttributes(data).complete callback
        
        dropGAuthDataForUser: (userId, callback = ()->)->
          UserToken.destroy({user_id: userId, type: MarketHelper.getTokenType("google_auth")}).complete callback

        generateEmailConfirmationTokenForUser: (userId, seed, callback = ()->)->
          data =
            user_id: userId
            type: "email_confirmation"
            token: crypto.createHash("sha1").update("email_confirmations-#{userId}-#{seed}-#{GLOBAL.appConfig().salt}-#{Date.now()}", "utf8").digest("hex")
          UserToken.findOrCreate({user_id: data.user_id, type: MarketHelper.getTokenType(data.type)}, data).complete (err, userToken, created)->
            return callback err, userToken  if created
            userToken.updateAttributes(data).complete callback

        generateChangePasswordTokenForUser: (userId, seed, callback = ()->)->
          data =
            user_id: userId
            type: "change_password"
            token: crypto.createHash("sha1").update("change_password-#{userId}-#{seed}-#{GLOBAL.appConfig().salt}-#{Date.now()}", "utf8").digest("hex")
          UserToken.findOrCreate({user_id: data.user_id, type: MarketHelper.getTokenType(data.type)}, data).complete (err, userToken, created)->
            return callback err, userToken  if created
            userToken.updateAttributes(data).complete callback

      instanceMethods:

        isValidGAuthPass: (pass)->
          UserToken.isValidGAuthPassForKey pass, @token

  UserToken