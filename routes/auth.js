(function() {
  var AuthStats, JsonRenderer, User, UserToken;

  User = GLOBAL.db.User;

  UserToken = GLOBAL.db.UserToken;

  AuthStats = GLOBAL.db.AuthStats;

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    var login;
    app.get("/signup", function(req, res) {
      return res.render("auth/signup");
    });
    app.get("/login", function(req, res) {
      return res.render("auth/login");
    });
    app.post("/login", function(req, res, next) {
      return login(req, res, next);
    });
    app.put("/login", function(req, res, next) {
      return login(req, res, next);
    });
    app.get("/logout", function(req, res) {
      req.logout();
      if (req.accepts("html")) {
        return res.redirect("/");
      }
      return res.json({});
    });
    app.get("/send-password", function(req, res) {
      var errors, success;
      if (req.query.error) {
        errors = [req.query.error];
      }
      success = req.query.success;
      return res.render("auth/send_password", {
        title: "Send Password - Coinnext.com",
        errors: errors,
        success: success
      });
    });
    app.post("/send-password", function(req, res) {
      var email;
      email = req.body.email;
      if (!email) {
        res.writeHead(303, {
          "Location": "/send-password"
        });
        return res.end();
      }
      return User.findByEmail(email, function(err, user) {
        if (!user) {
          res.writeHead(303, {
            "Location": "/send-password?error=wrong-user"
          });
          return res.end();
        }
        return user.sendChangePasswordLink(function() {
          res.writeHead(303, {
            "Location": "/send-password?success=true"
          });
          return res.end();
        });
      });
    });
    app.get("/change-password/:token", function(req, res) {
      var errors, token;
      token = req.params.token;
      if (req.query.error) {
        errors = [req.query.error];
      }
      return res.render("auth/change_password", {
        title: "Change Password - Coinnext.com",
        token: token,
        errors: errors
      });
    });
    app.post("/change-password", function(req, res) {
      var password, token;
      token = req.body.token;
      password = req.body.password;
      return User.findByToken(token, function(err, user) {
        if (!user) {
          res.writeHead(303, {
            "Location": "/change-password/" + token + "?error=wrong-token"
          });
          res.end();
        }
        return user.changePassword(password, function(err, u) {
          if (err) {
            console.error(err);
          }
          res.writeHead(303, {
            "Location": "/login"
          });
          return res.end();
        });
      });
    });
    app.post("/set-new-password", function(req, res) {
      var newPassword, password;
      password = req.body.password;
      newPassword = req.body.new_password;
      if (!req.user) {
        return JsonRenderer.error("Please auth.", res);
      }
      if (User.hashPassword(password) !== req.user.password) {
        return JsonRenderer.error("The old password is incorrect.", res);
      }
      return req.user.changePassword(newPassword, function(err, u) {
        if (err) {
          console.error(err);
        }
        return res.json({
          message: "The password was successfully changed."
        });
      });
    });
    app.get("/verify/:token", function(req, res) {
      var token;
      token = req.params.token;
      return User.findByToken(token, function(err, user) {
        if (!user) {
          return res.render("auth/verify", {
            title: "Verify Account - Coinnext.com"
          });
        }
        return user.setEmailVerified(function(err, u) {
          return res.render("auth/verify", {
            title: "Verify Account - Coinnext.com",
            user: u
          });
        });
      });
    });
    app.post("/google_auth", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res);
      }
      return res.json(UserToken.generateGAuthData());
    });
    app.put("/google_auth/:id?", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res);
      }
      if (!UserToken.isValidGAuthPassForKey(req.body.gauth_pass, req.body.gauth_key)) {
        return JsonRenderer.error("Invalid Google Authenticator code", res, 401);
      }
      return UserToken.addGAuthTokenForUser(req.body.gauth_key, req.user.id, function(err, user) {
        return res.json(user);
      });
    });
    app.del("/google_auth/:id?", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res);
      }
      return UserToken.isValidGAuthPassForUser(req.user.id, req.body.gauth_pass, function(err, isValid) {
        if (!isValid) {
          return JsonRenderer.error("Invalid Google Authenticator code", res, 401);
        }
        return UserToken.dropGAuthDataForUser(req.user.id, function() {
          return res.json(JsonRenderer.user(req.user));
        });
      });
    });
    return login = function(req, res, next) {
      return passport.authenticate("local", function(err, user, info) {
        if (err) {
          return JsonRenderer.error(err, res, 401);
        }
        if (!user) {
          return JsonRenderer.error("Invalid credentials", res, 401);
        }
        return req.logIn(user, function(err) {
          if (err) {
            return JsonRenderer.error("Invalid credentials", res, 401);
          }
          return UserToken.findByUserAndType(user.id, "google_auth", function(err, googleToken) {
            if (googleToken && !googleToken.isValidGAuthPass(req.body.gauth_pass)) {
              req.logout();
              return JsonRenderer.error("Invalid Google Authenticator code", res, 401);
            }
            res.json(JsonRenderer.user(req.user));
            return AuthStats.log({
              ip: req.ip,
              user: req.user
            }, req.user.email_auth_enabled);
          });
        });
      })(req, res, next);
    };
  };

}).call(this);
