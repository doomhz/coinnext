(function() {
  var crypto, speakeasy, _;

  crypto = require("crypto");

  speakeasy = require("speakeasy");

  _ = require("underscore");

  module.exports = function(sequelize, DataTypes) {
    var AdminUser;
    AdminUser = sequelize.define("AdminUser", {
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
      gauth_key: {
        type: DataTypes.STRING(32),
        unique: true
      }
    }, {
      tableName: "admin_users",
      classMethods: {
        findById: function(id, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return AdminUser.find(id).complete(callback);
        },
        findByEmail: function(email, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return AdminUser.find({
            where: {
              email: email
            }
          }).complete(callback);
        },
        hashPassword: function(password) {
          return crypto.createHash("sha256").update("" + password + (GLOBAL.appConfig().salt), "utf8").digest("hex");
        },
        createNewUser: function(data, callback) {
          var userData;
          userData = _.extend({}, data);
          userData.password = AdminUser.hashPassword(userData.password);
          return AdminUser.create(userData).complete(callback);
        }
      },
      instanceMethods: {
        isValidPassword: function(password) {
          return this.password === AdminUser.hashPassword(password);
        },
        generateGAuthData: function(callback) {
          var data;
          if (callback == null) {
            callback = function() {};
          }
          data = speakeasy.generate_key({
            name: "administratiecnx",
            length: 20,
            google_auth_qr: true
          });
          this.gauth_key = data.base32;
          return this.save().complete(function(err, user) {
            return callback(data, user);
          });
        },
        isValidGAuthPass: function(pass) {
          var currentPass;
          currentPass = speakeasy.time({
            key: this.gauth_key,
            encoding: "base32"
          });
          return currentPass === pass;
        },
        generateToken: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.token = crypto.createHash("sha256").update("" + this._id + (GLOBAL.appConfig().salt) + (Date.now()), "utf8").digest("hex");
          return this.save().complete(function(err, u) {
            return callback(u.token);
          });
        }
      }
    });
    return AdminUser;
  };

}).call(this);
