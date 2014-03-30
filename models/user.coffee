MarketHelper = require "../lib/market_helper"
crypto    = require "crypto"
speakeasy = require "speakeasy"
Emailer   = require "../lib/emailer"
phonetic  = require "phonetic"
_         = require "underscore"

module.exports = (sequelize, DataTypes) ->

  User = sequelize.define "User",
      uuid:
        type: DataTypes.UUID
        defaultValue: DataTypes.UUIDV4
        allowNull: false
        unique: true
        validate:
          isUUID: 4
      email:
        type: DataTypes.STRING
        allowNull: false
        unique: true
        validate:
          isEmail: true
      password:
        type: DataTypes.STRING
        allowNull: false
        validate:
          len: [5, 500]
      username:
        type: DataTypes.STRING
        allowNull: false
        unique: true
        validate:
          isAlphanumericAndUnderscore: (value)->
            message = "The username can have letters, numbers and underscores and should be longer than 4 characters and shorter than 16."
            throw new Error message  if not /^[a-zA-Z0-9_]{4,15}$/.test(value)
      email_verified:
        type: DataTypes.BOOLEAN
        allowNull: false
        defaultValue: false
      chat_enabled:
        type: DataTypes.BOOLEAN
        allowNull: false
        defaultValue: true
      email_auth_enabled:
        type: DataTypes.BOOLEAN
        allowNull: false
        defaultValue: true
    ,
      tableName: "users"
      classMethods:
        
        findById: (id, callback = ()->)->
          User.find(id).complete callback

        findByToken: (token, callback = ()->)->
          query =
            where:
              token: token
            include: [
              {model: GLOBAL.db.User}
            ]
          GLOBAL.db.UserToken.find(query).complete (err, userToken = {})->
            callback err, userToken.user

        findByEmail: (email, callback = ()->)->
          User.find({where:{email: email}}).complete callback

        hashPassword: (password)->
          crypto.createHash("sha1").update("#{password}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")
        
        createNewUser: (data, callback)->
          userData = _.extend({}, data)
          userData.password = User.hashPassword userData.password
          userData.username = User.generateUsername data.email
          User.create(userData).complete callback

        generateUsername: (seed)->
          seed = crypto.createHash("sha1").update("username_#{seed}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")
          phonetic.generate
            seed: seed

      instanceMethods:
        
        isValidPassword: (password)->
          @password is User.hashPassword(password)

        sendChangePasswordLink: (callback = ()->)->
          GLOBAL.db.UserToken.generateChangePasswordTokenForUser @id, @uuid, (err, userToken)=>
            siteUrl = GLOBAL.appConfig().emailer.host
            passUrl = "#{siteUrl}/change-password/#{userToken.token}"
            data =
              "site_url": siteUrl
              "pass_url": passUrl
            options =
              to:
                email: @email
              subject: "Change password request on Coinnext.com"
              template: "change_password"
            emailer = new Emailer options, data
            emailer.send (err, result)->
              console.error err  if err
            callback()

        sendEmailVerificationLink: (callback = ()->)->
          GLOBAL.db.UserToken.generateEmailConfirmationTokenForUser @id, @uuid, (err, userToken)=>
            siteUrl = GLOBAL.appConfig().emailer.host
            verificationUrl = "#{siteUrl}/verify/#{userToken.token}"
            data =
              "site_url": siteUrl
              "verification_url": verificationUrl
            options =
              to:
                email: @email
              subject: "Account confirmation on Coinnext.com"
              template: "confirm_email"
            emailer = new Emailer options, data
            emailer.send (err, result)->
              console.error err  if err
            callback()

        changePassword: (password, callback = ()->)->
          @password = User.hashPassword password
          @save().complete callback

        setEmailVerified: (callback = ()->)->
          @email_verified = true
          @save().complete callback

        canTrade: ()->
          @email_verified

        updateSettings: (data, callback = ()->)->
          @chat_enabled = !!data.chat_enabled  if data.chat_enabled?
          @email_auth_enabled = !!data.email_auth_enabled  if data.email_auth_enabled?
          @username = data.username  if data.username? and data.username isnt @username
          @save().complete callback

  User