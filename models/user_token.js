(function() {
  var crypto, speakeasy, _;

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  _ = require("underscore");

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
        unique: true
      }
    }, {
      tableName: "user_tokens",
      classMethods: {
        findByUserId: function(userId, callback) {
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
        generateGAuthPassByKey: function(key) {
          return speakeasy.time({
            key: key,
            encoding: "base32"
          });
        },
        isValidGAuthPassForKey: function(pass, key) {
          return UserToken.generateGAuthPassByKey(key) === pass;
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
            user_id: user_id,
            type: "google_auth",
            token: key
          };
          return UserToken.findOrCreate({
            user_id: data.user_id,
            type: data.type
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
            type: "google_auth"
          }).complete(callback);
        },
        generateChangePasswordToken: function(seed, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return crypto.createHash("sha1").update("" + seed + (GLOBAL.appConfig().salt) + (Date.now()), "utf8").digest("hex");
        }
      }
    });
    return UserToken;
  };

}).call(this);
