(function() {
  var Emailer, crypto, phonetic, speakeasy, _;

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  Emailer = require("../lib/emailer");

  phonetic = require("phonetic");

  _ = require("underscore");

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
      username: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
          isAlphanumericAndUnderscore: function(value) {
            var message;
            message = "The username can have letters, numbers and underscores and should be longer than 4 characters and shorter than 16.";
            if (!/^[a-zA-Z0-9_]{4,15}$/.test(value)) {
              throw new Error(message);
            }
          }
        }
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
      },
      chat_enabled: {
        type: DataTypes.BOOLEAN,
        defaultValue: true
      },
      email_auth_enabled: {
        type: DataTypes.BOOLEAN,
        defaultValue: true
      }
    }, {
      tableName: "users",
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
        },
        createNewUser: function(data, callback) {
          var userData;
          userData = _.extend({}, data);
          userData.password = User.hashPassword(userData.password);
          userData.username = User.generateUsername(data.email);
          return User.create(userData).complete(callback);
        },
        generateGAuthPassByKey: function(key) {
          return speakeasy.time({
            key: key,
            encoding: "base32"
          });
        },
        isValidGAuthPassForKey: function(pass, key) {
          return User.generateGAuthPassByKey(key) === pass;
        },
        generateUsername: function(seed) {
          seed = crypto.createHash("sha1").update("username_" + seed + (GLOBAL.appConfig().salt), "utf8").digest("hex");
          return phonetic.generate({
            seed: seed
          });
        }
      },
      instanceMethods: {
        isValidPassword: function(password) {
          return this.password === User.hashPassword(password);
        },
        generateGAuthData: function() {
          var data, gData;
          gData = speakeasy.generate_key({
            name: "coinnext.com",
            length: 20,
            google_auth_qr: true
          });
          return data = {
            gauth_qr: gData.google_auth_qr,
            gauth_key: gData.base32
          };
        },
        setGAuthData: function(key, callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.gauth_key = key;
          return this.save().complete(callback);
        },
        dropGAuthData: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.gauth_key = null;
          return this.save().complete(callback);
        },
        isValidGAuthPass: function(pass) {
          return User.generateGAuthPassByKey(this.gauth_key) === pass;
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
        },
        updateSettings: function(data, callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (data.chat_enabled != null) {
            this.chat_enabled = !!data.chat_enabled;
          }
          if (data.email_auth_enabled != null) {
            this.email_auth_enabled = !!data.email_auth_enabled;
          }
          if ((data.username != null) && data.username !== this.username) {
            this.username = data.username;
          }
          return this.save().complete(callback);
        }
      }
    });
    return User;
  };

}).call(this);
