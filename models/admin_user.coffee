crypto    = require "crypto"
speakeasy = require "speakeasy"
_         = require "underscore"

module.exports = (sequelize, DataTypes) ->

  AdminUser = sequelize.define "AdminUser",
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
      gauth_key:
        type: DataTypes.STRING(32)
        unique: true
    ,
      tableName: "admin_users"
      classMethods:
        
        findById: (id, callback = ()->)->
          AdminUser.find(id).complete callback

        findByEmail: (email, callback = ()->)->
          AdminUser.find({where:{email: email}}).complete callback

        hashPassword: (password)->
          crypto.createHash("sha256").update("#{password}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")
        
        createNewUser: (data, callback)->
          userData = _.extend({}, data)
          userData.password = AdminUser.hashPassword userData.password
          AdminUser.create(userData).complete callback

      instanceMethods:
        
        isValidPassword: (password)->
          @password is AdminUser.hashPassword(password)

        generateGAuthData: (callback = ()->)->
          data = speakeasy.generate_key
            name: "administratiecnx"
            length: 20
            google_auth_qr: true
          @gauth_key = data.base32
          @save().complete (err, user)->
            callback data, user

        isValidGAuthPass: (pass)->
          currentPass = speakeasy.time
            key: @gauth_key
            encoding: "base32"
          currentPass is pass

        generateToken: (callback = ()->)->
          @token = crypto.createHash("sha256").update("#{@_id}#{GLOBAL.appConfig().salt}#{Date.now()}", "utf8").digest("hex")
          @save().complete (err, u)->
            callback(u.token)

  AdminUser