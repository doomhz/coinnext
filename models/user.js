(function() {
  var User, UserSchema, crypto, exports, speakeasy;

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  UserSchema = new Schema({
    email: {
      type: String,
      index: {
        unique: true
      }
    },
    password: {
      type: String
    },
    gauth_data: {
      type: {}
    },
    created:  ({
      type: Date ,
      "default": Date.now ,
      index: true
    })
  });

  UserSchema.set("autoIndex", false);

  UserSchema.methods.isValidPassword = function(password) {
    return this.password === User.hashPassword(password);
  };

  UserSchema.methods.generateGAuthData = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.gauth_data = speakeasy.generate_key({
      name: "coinnext.com",
      length: 20,
      google_auth_qr: true
    });
    return this.save(callback);
  };

  UserSchema.methods.isValidGAuthPass = function(pass) {
    var currentPass;
    currentPass = speakeasy.time({
      key: this.gauth_data.base32,
      encoding: "base32"
    });
    return currentPass === pass;
  };

  UserSchema.statics.hashPassword = function(password) {
    return crypto.createHash("sha1").update("" + password + (GLOBAL.appConfig().salt), "utf8").digest("hex");
  };

  User = mongoose.model("User", UserSchema);

  exports = module.exports = User;

}).call(this);
