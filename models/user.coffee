crypto          = require "crypto"
speakeasy       = require "speakeasy"
uniqueValidator = require "mongoose-unique-validator"
Emailer         = require "../lib/emailer"

UserSchema = new Schema
  email:
    type: String
    index:
      unique: true
  password:
    type: String
  gauth_data:
    type: {}
  token:
    type: String
    index:
      unique: true
  email_verified:
    type: Boolean
    index: true
    default: false
  created: 
    type: Date 
    default: Date.now 
    index: true

UserSchema.set("autoIndex", false)

UserSchema.plugin uniqueValidator

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

UserSchema.methods.sendPasswordLink = (callback = ()->)->
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

UserSchema.methods.sendEmailVerificationLink = (callback = ()->)->
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

UserSchema.methods.generateToken = (callback = ()->)->
  @token = crypto.createHash("sha1").update("#{@_id}#{GLOBAL.appConfig().salt}#{Date.now()}", "utf8").digest("hex")
  @save (err, u)->
    callback(u.token)

UserSchema.methods.canTrade = ()->
  @email_verified

UserSchema.statics.findByToken = (token, callback = ()->)->
  User.findOne({token: token}).exec (err, user)->
    callback(err, user)

UserSchema.statics.hashPassword = (password)->
  crypto.createHash("sha1").update("#{password}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")

UserSchema.path("email").validate (value)->
    emailPattern = /^\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b$/i
    emailPattern.test value
  , "Invalid email"

UserSchema.path("password").validate (value)->
    value.length > 4
  , "The password is too short. 5 chars min."

User = mongoose.model "User", UserSchema
exports = module.exports = User