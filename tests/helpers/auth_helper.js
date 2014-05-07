var _ = require("underscore");
var request = require("supertest");
var userData = {
  email: "test@test.com",
  password: "test12345_"
};

Auth = {
  login: function (options, callback) {
    var data = _.extend(userData, typeof(options) !== "function" ? options : {});
    data.email_verified = typeof(options.email_verified) !== "undefined" ? options.email_verified : true;
    var cb = typeof(options) === "function" ? options : callback;
    GLOBAL.db.User.createNewUser(data, function (err, user) {
      if (err) {console.error(err)};
      request(GLOBAL.appConfig().app_host)
      .post("/login")
      .send(userData)
      .end(function (err, res) {
        cb(err, res.headers['set-cookie'], user, res);
      });
    });
  }
};

module.exports = Auth;