(function() {
  var JsonRenderer, User, _;

  User = require('../models/user');

  JsonRenderer = require('../lib/json_renderer');

  _ = require("underscore");

  module.exports = function(app) {
    var login, renderError;
    app.post("/user", function(req, res) {
      var user;
      user = new User({
        email: req.body.email,
        password: User.hashPassword(req.body.password)
      });
      return user.save(function(err) {
        if (err) {
          return renderError(err, res);
        }
        return res.json(JsonRenderer.user(user));
      });
    });
    app.post("/login", function(req, res, next) {
      return login(req, res, next);
    });
    app.put("/login", function(req, res, next) {
      return login(req, res, next);
    });
    app.get("/user/:id?", function(req, res) {
      if (!req.user) {
        return renderError(null, res);
      }
      return res.json(JsonRenderer.user(req.user));
    });
    app.get("/logout", function(req, res) {
      req.logout();
      if (req.accepts("html")) {
        return res.redirect("/");
      } else {
        return res.json({});
      }
    });
    app.get("/generate_gauth", function(req, res) {
      if (!req.user) {
        return renderError(null, res);
      }
      return req.user.generateGAuthData(function() {
        return res.json(JsonRenderer.user(req.user));
      });
    });
    login = function(req, res, next) {
      return passport.authenticate("local", function(err, user, info) {
        if (err) {
          return renderError(err, res, 401);
        }
        if (!user) {
          return renderError("Invalid credentials", res, 401);
        }
        return req.logIn(user, function(err) {
          if (err) {
            return renderError("Invalid credentials", res, 401);
          }
          if (user.gauth_data && !user.isValidGAuthPass(req.body.gauth_pass)) {
            req.logout();
            return renderError("Invalid Google Authenticator code", res, 401);
          }
          return res.json(JsonRenderer.user(req.user));
        });
      })(req, res, next);
    };
    return renderError = function(err, res, code) {
      var key, message, val, _ref;
      if (code == null) {
        code = 409;
      }
      res.statusCode = code;
      message = "";
      if (_.isString(err)) {
        message = err;
      } else if (_.isObject(err) && err.name === "ValidationError") {
        _ref = err.errors;
        for (key in _ref) {
          val = _ref[key];
          if (val.path === "email" && val.message === "unique") {
            message += "E-mail is already taken. ";
          } else {
            message += "" + val.message + " ";
          }
        }
      }
      return res.json({
        error: message
      });
    };
  };

}).call(this);
