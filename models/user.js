(function() {
  var BANNED_USERNAMES_REGEX, Emailer, MarketHelper, crypto, phonetic, speakeasy, _;

  MarketHelper = require("../lib/market_helper");

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  Emailer = require("../lib/emailer");

  phonetic = require("phonetic");

  _ = require("underscore");

  BANNED_USERNAMES_REGEX = /admin|coinnext/ig;

  module.exports = function(sequelize, DataTypes) {
    var User;
    User = sequelize.define("User", {
      uuid: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        allowNull: false,
        unique: true,
        validate: {
          isUUID: 4
        }
      },
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
          },
          isAllowedUsername: function(value) {
            var message;
            message = "This username is not allowed";
            if (BANNED_USERNAMES_REGEX.test(value)) {
              throw new Error(message);
            }
          }
        }
      },
      email_verified: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
      },
      chat_enabled: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true
      },
      email_auth_enabled: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
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
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              token: token
            },
            include: [
              {
                model: GLOBAL.db.User
              }
            ]
          };
          return GLOBAL.db.UserToken.find(query).complete(function(err, userToken) {
            if (userToken == null) {
              userToken = {};
            }
            return callback(err, userToken.user);
          });
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
        findByUsername: function(username, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return User.find({
            where: {
              username: username
            }
          }).complete(callback);
        },
        hashPassword: function(password) {
          return crypto.createHash("sha256").update("" + password + (GLOBAL.appConfig().salt), "utf8").digest("hex");
        },
        passwordMeetsRequirements: function(password) {
          if (password == null) {
            password = "";
          }
          if (password.length < 8) {
            return false;
          }
          if (!/[0-9]/.test(password)) {
            return false;
          }
          return true;
        },
        createNewUser: function(data, callback) {
          var userData;
          userData = _.extend({}, data);
          if (!User.passwordMeetsRequirements(userData.password)) {
            return callback("Your password doest not meet the minimum requirements. It must be at least 8 characters and cointain at least one one number.", null);
          }
          userData.password = User.hashPassword(userData.password);
          userData.username = User.generateUsername(data.email);
          return User.create(userData).complete(callback);
        },
        generateUsername: function(seed) {
          seed = crypto.createHash("sha256").update("username_" + seed + (GLOBAL.appConfig().salt), "utf8").digest("hex");
          return phonetic.generate({
            seed: seed
          });
        }
      },
      instanceMethods: {
        isValidPassword: function(password) {
          return this.password === User.hashPassword(password);
        },
        sendChangePasswordLink: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          return GLOBAL.db.UserToken.generateChangePasswordTokenForUser(this.id, this.uuid, (function(_this) {
            return function(err, userToken) {
              var data, emailer, options, passUrl;
              passUrl = "/change-password/" + userToken.token;
              data = {
                "pass_url": passUrl
              };
              options = {
                to: {
                  email: _this.email
                },
                subject: "Change password request",
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
          })(this));
        },
        sendEmailVerificationLink: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          if (this.email_verified) {
            return callback();
          }
          return GLOBAL.db.UserToken.generateEmailConfirmationTokenForUser(this.id, this.uuid, (function(_this) {
            return function(err, userToken) {
              var data, emailer, options;
              data = {
                "verification_url": "/verify/" + userToken.token
              };
              options = {
                to: {
                  email: _this.email
                },
                subject: "Email verification",
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
          })(this));
        },
        changePassword: function(password, callback) {
          var newHash, oldHash;
          if (callback == null) {
            callback = function() {};
          }
          oldHash = this.password;
          newHash = User.hashPassword(password);
          if (newHash === oldHash) {
            return callback("You new password must be different from the old one.");
          }
          if (!User.passwordMeetsRequirements(password)) {
            return callback("Your password doest not meet the minimum requirements. It must be at least 8 characters and cointain at least one one number.");
          }
          this.password = newHash;
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
        },
        recenltySignedUp: function() {
          return this.created_at > (Date.now() - 60000);
        }
      }
    });
    return User;
  };

}).call(this);
