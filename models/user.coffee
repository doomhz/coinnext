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
      gauth_key:
        type: DataTypes.STRING(32)
        unique: true
      token:
        type: DataTypes.STRING(40)
        unique: true
      email_verified:
        type: DataTypes.BOOLEAN
        defaultValue: false
      chat_enabled:
        type: DataTypes.BOOLEAN
        defaultValue: true
      email_auth_enabled:
        type: DataTypes.BOOLEAN
        defaultValue: true
    ,
      tableName: "users"
      classMethods:
        
        findById: (id, callback = ()->)->
          User.find(id).complete callback

        findByToken: (token, callback = ()->)->
          User.find({where:{token: token}}).complete callback

        findByEmail: (email, callback = ()->)->
          User.find({where:{email: email}}).complete callback

        hashPassword: (password)->
          crypto.createHash("sha1").update("#{password}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")
        
        createNewUser: (data, callback)->
          userData = _.extend({}, data)
          userData.password = User.hashPassword userData.password
          userData.username = User.generateUsername data.email
          User.create(userData).complete callback

        generateGAuthPassByKey: (key)->
          speakeasy.time
            key: key
            encoding: "base32"

        isValidGAuthPassForKey: (pass, key)->
          User.generateGAuthPassByKey(key) is pass

        generateUsername: (seed)->
          seed = crypto.createHash("sha1").update("username_#{seed}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")
          phonetic.generate
            seed: seed

      instanceMethods:
        
        isValidPassword: (password)->
          @password is User.hashPassword(password)

        generateGAuthData: ()->
          gData = speakeasy.generate_key
            name: "coinnext.com"
            length: 20
            google_auth_qr: true
          data =
            gauth_qr: gData.google_auth_qr
            gauth_key: gData.base32

        setGAuthData: (key, callback = ()->)->
          @gauth_key = key
          @save().complete callback
        
        dropGAuthData: (callback = ()->)->
          @gauth_key = null
          @save().complete callback

        isValidGAuthPass: (pass)->
          User.generateGAuthPassByKey(@gauth_key) is pass

        sendPasswordLink: (callback = ()->)->
          siteUrl = GLOBAL.appConfig().emailer.host
          passUrl = "#{siteUrl}/change-password/#{@token}"
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
          siteUrl = GLOBAL.appConfig().emailer.host
          verificationUrl = "#{siteUrl}/verify/#{@token}"
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

        generateToken: (callback = ()->)->
          @token = crypto.createHash("sha1").update("#{@_id}#{GLOBAL.appConfig().salt}#{Date.now()}", "utf8").digest("hex")
          @save().complete (err, u)->
            callback(u.token)

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