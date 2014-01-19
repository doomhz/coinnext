(function() {
  var Emailer, User, UserSchema, crypto, exports, speakeasy, uniqueValidator;

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  uniqueValidator = require("mongoose-unique-validator");

  Emailer = require("../lib/emailer");

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
    token: {
      type: String,
      index: {
        unique: true
      }
    },
    email_verified: {
      type: Boolean,
      index: true,
      "default": false
    },
    created:  ({
      type: Date ,
      "default": Date.now ,
      index: true
    })
  });

  UserSchema.set("autoIndex", false);

  UserSchema.plugin(uniqueValidator);

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

  UserSchema.methods.sendPasswordLink = function(callback) {
    var data, emailer, options, passUrl, siteUrl;
    if (callback == null) {
      callback = function() {};
    }
    siteUrl = GLOBAL.appConfig().emailer.host;
    passUrl = "" + siteUrl + "/change-password/" + this.token;
    data = {
      "site_url": siteUrl,
      "pass_url": passUrl
    };
    options = {
      to: {
        email: this.email
      },
      subject: "Change password request on Coinnext.com",
      template: "change_password"
    };
    emailer = new Emailer(options, data);
    emailer.send(function(err, result) {
      if (err) {
        return console.error(err);
      }
    });
    return callback();
  };

  UserSchema.methods.sendEmailVerificationLink = function(callback) {
    var data, emailer, options, siteUrl, verificationUrl;
    if (callback == null) {
      callback = function() {};
    }
    siteUrl = GLOBAL.appConfig().emailer.host;
    verificationUrl = "" + siteUrl + "/verify/" + this.id;
    data = {
      "site_url": siteUrl,
      "verification_url": verificationUrl
    };
    options = {
      to: {
        email: this.email
      },
      subject: "Account confirmation on Coinnext.com",
      template: "confirm_email"
    };
    emailer = new Emailer(options, data);
    emailer.send(function(err, result) {
      if (err) {
        return console.error(err);
      }
    });
    return callback();
  };

  UserSchema.methods.generateToken = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.token = crypto.createHash("sha1").update("" + this._id + (GLOBAL.appConfig().salt) + (Date.now()), "utf8").digest("hex");
    return this.save(function(err, u) {
      return callback(u.token);
    });
  };

  UserSchema.statics.findByToken = function(token, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return User.findOne({
      token: token
    }).exec(function(err, user) {
      return callback(err, user);
    });
  };

  UserSchema.statics.hashPassword = function(password) {
    return crypto.createHash("sha1").update("" + password + (GLOBAL.appConfig().salt), "utf8").digest("hex");
  };

  UserSchema.path("email").validate(function(value) {
    var emailPattern;
    emailPattern = /^\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b$/i;
    return emailPattern.test(value);
  }, "Invalid email");

  UserSchema.path("password").validate(function(value) {
    return value.length > 4;
  }, "The password is too short. 5 chars min.");

  User = mongoose.model("User", UserSchema);

  exports = module.exports = User;

}).call(this);
