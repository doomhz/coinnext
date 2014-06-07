MarketHelper = require "../lib/market_helper"
crypto    = require "crypto"
speakeasy = require "speakeasy"
Emailer   = require "../lib/emailer"
phonetic  = require "phonetic"
_         = require "underscore"

BANNED_USERNAMES_REGEX = /admin|coinnext/ig

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
          isAllowedUsername: (value)->
            message = "This username is not allowed"
            throw new Error message if BANNED_USERNAMES_REGEX.test(value)
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

        findByUsername: (username, callback = ()->)->
          User.find({where:{username: username}}).complete callback
        
        hashPassword: (password)->
          crypto.createHash("sha256").update("#{password}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")
        
        passwordMeetsRequirements: (password = "")->
          return false if password.length < 8           # min 8 characters
          return false if not /[0-9]/.test(password)    # at least one number
          return true

        createNewUser: (data, callback)->
          userData = _.extend({}, data)
          if not User.passwordMeetsRequirements(userData.password)
            return callback "Your password doest not meet the minimum requirements. It must be at least 8 characters and cointain at least one one number.", null
          userData.password = User.hashPassword userData.password
          userData.username = User.generateUsername data.email
          User.create(userData).complete callback

        generateUsername: (seed)->
          seed = crypto.createHash("sha256").update("username_#{seed}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")
          phonetic.generate
            seed: seed

      instanceMethods:
        
        isValidPassword: (password)->
          @password is User.hashPassword(password)

        sendChangePasswordLink: (callback = ()->)->
          GLOBAL.db.UserToken.generateChangePasswordTokenForUser @id, @uuid, (err, userToken)=>
            passUrl = "/change-password/#{userToken.token}"
            data =
              "pass_url": passUrl
            options =
              to:
                email: @email
              subject: "Change password request"
              template: "change_password"
            emailer = new Emailer options, data
            emailer.send (err, result)->
              console.error err  if err
            callback()

        sendEmailVerificationLink: (callback = ()->)->
          return callback()  if @email_verified
          GLOBAL.db.UserToken.generateEmailConfirmationTokenForUser @id, @uuid, (err, userToken)=>
            data =
              "verification_url": "/verify/#{userToken.token}"
            options =
              to:
                email: @email
              subject: "Email verification"
              template: "confirm_email"
            emailer = new Emailer options, data
            emailer.send (err, result)->
              console.error err  if err
            callback()

        changePassword: (password, callback = ()->)->
          oldHash = @password
          newHash = User.hashPassword password
          return callback "You new password must be different from the old one."  if newHash is oldHash
          return callback "Your password doest not meet the minimum requirements. It must be at least 8 characters and cointain at least one one number."  if not User.passwordMeetsRequirements(password)
          @password = newHash
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

        recenltySignedUp: ()->
          @created_at > (Date.now() - 60000)

  User