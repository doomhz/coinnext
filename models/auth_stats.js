(function() {
  var Emailer, ipFormatter;

  require("date-utils");

  ipFormatter = require("ip");

  Emailer = require("../lib/emailer");

  module.exports = function(sequelize, DataTypes) {
    var AuthStats;
    AuthStats = sequelize.define("AuthStats", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      ip: {
        type: DataTypes.INTEGER,
        allowNull: true,
        set: function(ip) {
          return this.setDataValue("ip", ipFormatter.toLong(ip));
        },
        get: function() {
          return ipFormatter.fromLong(this.getDataValue("ip"));
        }
      }
    }, {
      tableName: "auth_stats",
      classMethods: {
        findByUser: function(userId, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return AuthStats.findAll({
            where: {
              user_id: userId
            }
          }).complete(callback);
        },
        log: function(data, sendByMail, callback) {
          var stats;
          if (sendByMail == null) {
            sendByMail = true;
          }
          if (callback == null) {
            callback = function() {};
          }
          stats = {
            user_id: data.user.id,
            ip: data.ip
          };
          return AuthStats.create(stats).complete(function(err, authStats) {
            if (sendByMail) {
              AuthStats.sendUserLoginNotice(authStats, data.user.email);
            }
            return callback(err, stats);
          });
        },
        sendUserLoginNotice: function(stats, email, callback) {
          var data, emailer, options;
          if (callback == null) {
            callback = function() {};
          }
          data = {
            ip: stats.ip || "unknown",
            auth_date: stats.created_at.toFormat("MMMM D, YYYY at HH24:MI"),
            email: email
          };
          options = {
            to: {
              email: email
            },
            subject: "Login on Coinnext.com",
            template: "user_login_notice"
          };
          emailer = new Emailer(options, data);
          emailer.send(function(err, result) {
            if (err) {
              return console.error(err);
            }
          });
          return callback();
        }
      }
    });
    return AuthStats;
  };

}).call(this);
