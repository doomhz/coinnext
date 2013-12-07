crypto = require "crypto"

UserSchema = new Schema
  email:
    type: String
    index:
      unique: true
  password:
    type: String
  created: 
    type: Date     
    default: Date.now     
    index: true

UserSchema.set("autoIndex", false)

UserSchema.pre "save", (next)->
  @password = User.hashPassword @password
  next()

UserSchema.statics.hashPassword = (password)->
  crypto.createHash("sha1").update("#{password}#{GLOBAL.appConfig().salt}", "utf8").digest("hex")

UserSchema.methods.isValidPassword = (password)->
  @password is User.hashPassword(password)

User = mongoose.model "User", UserSchema
exports = module.exports = User