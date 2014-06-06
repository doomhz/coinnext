(function() {
  var MarketHelper, crypto, speakeasy;

  MarketHelper = require("../lib/market_helper");

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  module.exports = function(sequelize, DataTypes) {
    var TOKEN_VALIDITY_TIME, UserToken;
    TOKEN_VALIDITY_TIME = 86400000;
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
      },
      active: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true
      }
    }, {
      tableName: "user_tokens",
      classMethods: {
        findByToken: function(token, callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              token: token,
              active: true,
              created_at: {
                gt: UserToken.getMaxExpirationTime()
              }
            }
          };
          return UserToken.find(query).complete(callback);
        },
        findByUserAndType: function(userId, type, callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              user_id: userId,
              type: MarketHelper.getTokenType(type),
              active: true
            }
          };
          if (UserToken.expiresInTime(type)) {
            query.where.created_at = {
              gt: UserToken.getMaxExpirationTime()
            };
          }
          return UserToken.find(query).complete(callback);
        },
        findEmailConfirmationToken: function(userId, callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            where: {
              user_id: userId,
              type: MarketHelper.getTokenType("email_confirmation"),
              active: true
            }
          };
          return UserToken.find(query).complete(callback);
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
            if (!googleToken) {
              return callback(null, false);
            }
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
          return UserToken.create(data).complete(callback);
        },
        dropGAuthDataForUser: function(userId, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return UserToken.update({
            active: false
          }, {
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
            token: crypto.createHash("sha256").update("email_confirmations-" + userId + "-" + seed + "-" + (GLOBAL.appConfig().salt) + "-" + (Date.now()), "utf8").digest("hex")
          };
          return UserToken.create(data).complete(callback);
        },
        generateChangePasswordTokenForUser: function(userId, seed, callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = {
            user_id: userId,
            type: "change_password",
            token: crypto.createHash("sha256").update("change_password-" + userId + "-" + seed + "-" + (GLOBAL.appConfig().salt) + "-" + (Date.now()), "utf8").digest("hex")
          };
          return UserToken.create(data).complete(callback);
        },
        getMaxExpirationTime: function() {
          return new Date(Date.now() - TOKEN_VALIDITY_TIME);
        },
        invalidateByToken: function(token, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return UserToken.update({
            active: false
          }, {
            token: token
          }).complete(callback);
        },
        expiresInTime: function(type) {
          return type !== "google_auth";
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
