crypto = require "crypto"
speakeasy = require "speakeasy"

UserSchema = new Schema
  email:
    type: String
    index:
      unique: true
  password:
    type: String
  gauth_data:
    type: {}
  created: 
    type: Date     
    default: Date.now     
    index: true

UserSchema.set("autoIndex", false)

UserSchema.methods.isValidPassword = (password)->
  @password is User.hashPassword(password)

UserSchema.methods.generateGAuthData = (callback = ()->)->
  @gauth_data = speakeasy.generate_key
    name: "coinnext.com"
    length: 20
    google_auth_qr: true
  @save callback

UserSchema.methods.isValidGAuthPass = (pass)->
  currentPass = speakeasy.time
    key: @gauth_data.base32
    encoding: "base32"
  currentPass is pass

UserSchema.statics.hashPassword = (password)->
  crypto.createHash("sha1").update("#{password}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")

User = mongoose.model "User", UserSchema
exports = module.exports = User