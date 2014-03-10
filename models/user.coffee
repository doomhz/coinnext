crypto    = require "crypto"
speakeasy = require "speakeasy"
Emailer   = require "../lib/emailer"
_         = require "underscore"

module.exports = (sequelize, DataTypes) ->

  User = sequelize.define "User",
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
      gauth_data:
        type: DataTypes.TEXT
      gauth_key:
        type: DataTypes.STRING(32)
        unique: true
      token:
        type: DataTypes.STRING(40)
        unique: true
      email_verified:
        type: DataTypes.BOOLEAN
        defaultValue: false
    ,
      tableName: "users"
      getterMethods:

        google_auth_data: ()->
          JSON.parse @gauth_data

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
          User.create(userData).complete callback

      instanceMethods:
        
        isValidPassword: (password)->
          @password is User.hashPassword(password)

        generateGAuthData: (callback = ()->)->
          data = speakeasy.generate_key
            name: "coinnext.com"
            length: 20
            google_auth_qr: true
          @gauth_data = JSON.stringify data
          @gauth_key = data.base32
          @save().complete callback

        isValidGAuthPass: (pass)->
          currentPass = speakeasy.time
            key: @gauth_key
            encoding: "base32"
          currentPass is pass

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

  User