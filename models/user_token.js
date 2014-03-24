(function() {
  var MarketHelper, crypto, speakeasy;

  MarketHelper = require("../lib/market_helper");

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  module.exports = function(sequelize, DataTypes) {
    var UserToken;
    UserToken = sequelize.define("UserToken", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      type: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        comment: "email_confirmation, google_auth, change_password",
        get: function() {
          return MarketHelper.getTokenTypeLiteral(this.getDataValue("type"));
        },
        set: function(type) {
          return this.setDataValue("type", MarketHelper.getTokenType(type));
        }
      },
      token: {
        type: DataTypes.STRING(100),
        unique: true,
        allowNull: false
      }
    }, {
      tableName: "user_tokens",
      classMethods: {
        findByUser: function(userId, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return UserToken.find({
            where: {
              user_id: userId
            }
          }).complete(callback);
        },
        findByToken: function(token, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return UserToken.find({
            where: {
              token: token
            }
          }).complete(callback);
        },
        findByUserAndType: function(userId, type, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return UserToken.find({
            where: {
              user_id: userId,
              type: MarketHelper.getTokenType(type)
            }
          }).complete(callback);
        },
        generateGAuthPassByKey: function(key) {
          return speakeasy.time({
            key: key,
            encoding: "base32"
          });
        },
        isValidGAuthPassForKey: function(pass, key) {
          return UserToken.generateGAuthPassByKey(key) === pass;
        },
        isValidGAuthPassForUser: function(userId, pass, callback) {
          return UserToken.findByUserAndType(userId, "google_auth", function(err, googleToken) {
            return callback(err, UserToken.isValidGAuthPassForKey(pass, googleToken.token));
          });
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
        addGAuthTokenForUser: function(key, userId, callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = {
            user_id: userId,
            type: "google_auth",
            token: key
          };
          return UserToken.findOrCreate({
            user_id: data.user_id,
            type: MarketHelper.getTokenType(data.type)
          }, data).complete(function(err, userToken, created) {
            if (created) {
              return callback(err, userToken);
            }
            return userToken.updateAttributes(data).complete(callback);
          });
        },
        dropGAuthDataForUser: function(userId, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return UserToken.destroy({
            user_id: userId,
            type: MarketHelper.getTokenType("google_auth")
          }).complete(callback);
        },
        generateEmailConfirmationTokenForUser: function(userId, seed, callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = {
            user_id: userId,
            type: "email_confirmation",
            token: crypto.createHash("sha1").update("email_confirmations-" + userId + "-" + seed + "-" + (GLOBAL.appConfig().salt) + "-" + (Date.now()), "utf8").digest("hex")
          };
          return UserToken.findOrCreate({
            user_id: data.user_id,
            type: MarketHelper.getTokenType(data.type)
          }, data).complete(function(err, userToken, created) {
            if (created) {
              return callback(err, userToken);
            }
            return userToken.updateAttributes(data).complete(callback);
          });
        },
        generateChangePasswordTokenForUser: function(userId, seed, callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = {
            user_id: userId,
            type: "change_password",
            token: crypto.createHash("sha1").update("change_password-" + userId + "-" + seed + "-" + (GLOBAL.appConfig().salt) + "-" + (Date.now()), "utf8").digest("hex")
          };
          return UserToken.findOrCreate({
            user_id: data.user_id,
            type: MarketHelper.getTokenType(data.type)
          }, data).complete(function(err, userToken, created) {
            if (created) {
              return callback(err, userToken);
            }
            return userToken.updateAttributes(data).complete(callback);
          });
        }
      },
      instanceMethods: {
        isValidGAuthPass: function(pass) {
          return UserToken.isValidGAuthPassForKey(pass, this.token);
        }
      }
    });
    return UserToken;
  };

}).call(this);
