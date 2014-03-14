(function() {
  var Emailer;

  require("date-utils");

  Emailer = require("../lib/emailer");

  module.exports = function(sequelize, DataTypes) {
    var AuthStats;
    AuthStats = sequelize.define("AuthStats", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      ip: {
        type: DataTypes.STRING,
        allowNull: true
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
          var data, emailer, options, siteUrl;
          if (callback == null) {
            callback = function() {};
          }
          siteUrl = GLOBAL.appConfig().emailer.host;
          data = {
            site_url: siteUrl,
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
