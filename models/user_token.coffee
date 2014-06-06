MarketHelper = require "../lib/market_helper"
crypto    = require "crypto"
speakeasy = require "speakeasy"

module.exports = (sequelize, DataTypes) ->

  TOKEN_VALIDITY_TIME = 86400000 # 24 hours

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
      active:
        type: DataTypes.BOOLEAN
        allowNull: false
        defaultValue: true
    ,
      tableName: "user_tokens"
      classMethods:
        
        findByToken: (token, callback = ()->)->
          query =
            where:
              token: token
              active: true
              created_at:
                gt: UserToken.getMaxExpirationTime()
          UserToken.find(query).complete callback

        findByUserAndType: (userId, type, callback = ()->)->
          query =
            where:
              user_id: userId
              type: MarketHelper.getTokenType(type)
              active: true
          if UserToken.expiresInTime type
            query.where.created_at =
              gt: UserToken.getMaxExpirationTime()
          UserToken.find(query).complete callback

        findEmailConfirmationToken: (userId, callback = ()->)->
          query =
            where:
              user_id: userId
              type: MarketHelper.getTokenType("email_confirmation")
              active: true
          UserToken.find(query).complete callback

        generateGAuthPassByKey: (key)->
          speakeasy.time
            key: key
            encoding: "base32"

        isValidGAuthPassForKey: (pass, key)->
          UserToken.generateGAuthPassByKey(key) is pass

        isValidGAuthPassForUser: (userId, pass, callback)->
          UserToken.findByUserAndType userId, "google_auth", (err, googleToken)->
            return callback null, false  if not googleToken
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
          UserToken.create(data).complete callback
        
        dropGAuthDataForUser: (userId, callback = ()->)->
          UserToken.update({active: false}, {user_id: userId, type: MarketHelper.getTokenType("google_auth")}).complete callback

        generateEmailConfirmationTokenForUser: (userId, seed, callback = ()->)->
          data =
            user_id: userId
            type: "email_confirmation"
            token: crypto.createHash("sha256").update("email_confirmations-#{userId}-#{seed}-#{GLOBAL.appConfig().salt}-#{Date.now()}", "utf8").digest("hex")
          UserToken.create(data).complete callback

        generateChangePasswordTokenForUser: (userId, seed, callback = ()->)->
          data =
            user_id: userId
            type: "change_password"
            token: crypto.createHash("sha256").update("change_password-#{userId}-#{seed}-#{GLOBAL.appConfig().salt}-#{Date.now()}", "utf8").digest("hex")
          UserToken.create(data).complete callback

        getMaxExpirationTime: ()->
          new Date(Date.now() - TOKEN_VALIDITY_TIME)

        invalidateByToken: (token, callback = ()->)->
          UserToken.update({active: false}, {token: token}).complete callback

        expiresInTime: (type)->
          type isnt "google_auth"

      instanceMethods:

        isValidGAuthPass: (pass)->
          UserToken.isValidGAuthPassForKey pass, @token

  UserToken