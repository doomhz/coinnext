(function() {
  var Emailer, crypto, speakeasy;

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  Emailer = require("../lib/emailer");

  module.exports = function(sequelize, DataTypes) {
    var User;
    User = sequelize.define("User", {
      email: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
          isEmail: true
        }
      },
      password: {
        type: DataTypes.STRING,
        allowNull: false,
        validate: {
          len: [5, 500]
        }
      },
      gauth_data: {
        type: DataTypes.TEXT
      },
      gauth_key: {
        type: DataTypes.STRING(32),
        unique: true
      },
      token: {
        type: DataTypes.STRING(40),
        unique: true
      },
      email_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
      }
    }, {
      underscored: true,
      tableName: "users",
      getterMethods: {
        google_auth_data: function() {
          return JSON.parse(this.gauth_data);
        }
      },
      classMethods: {
        findById: function(id, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return User.find(id).complete(callback);
        },
        findByToken: function(token, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return User.find({
            where: {
              token: token
            }
          }).complete(callback);
        },
        findByEmail: function(email, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return User.find({
            where: {
              email: email
            }
          }).complete(callback);
        },
        hashPassword: function(password) {
          return crypto.createHash("sha1").update("" + password + (GLOBAL.appConfig().salt), "utf8").digest("hex");
        }
      },
      instanceMethods: {
        isValidPassword: function(password) {
          return this.password === User.hashPassword(password);
        },
        generateGAuthData: function(callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = speakeasy.generate_key({
            name: "coinnext.com",
            length: 20,
            google_auth_qr: true
          });
          this.gauth_data = JSON.stringify(data);
          this.gauth_key = data.base32;
          return this.save().complete(callback);
        },
        isValidGAuthPass: function(pass) {
          var currentPass;
          currentPass = speakeasy.time({
            key: this.gauth_key,
            encoding: "base32"
          });
          return currentPass === pass;
        },
        sendPasswordLink: function(callback) {
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
        },
        sendEmailVerificationLink: function(callback) {
          var data, emailer, options, siteUrl, verificationUrl;
          if (callback == null) {
            callback = function() {};
          }
          siteUrl = GLOBAL.appConfig().emailer.host;
          verificationUrl = "" + siteUrl + "/verify/" + this.token;
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
        },
        generateToken: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.token = crypto.createHash("sha1").update("" + this._id + (GLOBAL.appConfig().salt) + (Date.now()), "utf8").digest("hex");
          return this.save().complete(function(err, u) {
            return callback(u.token);
          });
        },
        changePassword: function(password, callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.password = User.hashPassword(password);
          return this.save().complete(callback);
        },
        setEmailVerified: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.email_verified = true;
          return this.save().complete(callback);
        },
        canTrade: function() {
          return this.email_verified;
        }
      }
    });
    return User;
  };

}).call(this);
