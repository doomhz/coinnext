(function() {
  var AuthStats, JsonRenderer, User, UserToken, reCaptcha;

  reCaptcha = require("recaptcha-async");

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
      var oldCsrf, oldStagingAuth;
      req.logout();
      oldStagingAuth = req.session.staging_auth;
      oldCsrf = req.session.csrfSecret;
      return req.session.regenerate(function() {
        req.session.staging_auth = oldStagingAuth;
        req.session.csrfSecret = oldCsrf;
        if (req.accepts("html")) {
          return res.redirect("/");
        }
        return res.json({});
      });
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
        success: success,
        recaptchaPublicKey: GLOBAL.appConfig().recaptcha.public_key
      });
    });
    app.post("/send-password", function(req, res) {
      var dataIsLoaded, email, recaptcha;
      email = req.body.email;
      if (!email) {
        return res.redirect("/send-password");
      }
      dataIsLoaded = false;
      recaptcha = new reCaptcha.reCaptcha();
      recaptcha.on("data", function(captchaRes) {
        if (!dataIsLoaded) {
          dataIsLoaded = true;
          if (!captchaRes.is_valid) {
            return res.redirect("/send-password?error=invalid-captcha");
          }
          return User.findByEmail(email, function(err, user) {
            if (!user) {
              return res.redirect("/send-password?success=true");
            }
            return user.sendChangePasswordLink(function() {
              return res.redirect("/send-password?success=true");
            });
          });
        }
      });
      return recaptcha.checkAnswer(GLOBAL.appConfig().recaptcha.private_key, req.connection.remoteAddress, req.body.recaptcha_challenge_field, req.body.recaptcha_response_field);
    });
    app.get("/change-password/:token", function(req, res) {
      var oldCsrf, oldStagingAuth, token;
      token = req.params.token;
      req.logout();
      oldStagingAuth = req.session.staging_auth;
      oldCsrf = req.session.csrfSecret;
      return req.session.regenerate(function() {
        req.session.staging_auth = oldStagingAuth;
        req.session.csrfSecret = oldCsrf;
        return UserToken.findByToken(token, function(err, userToken) {
          var errors;
          if (!userToken) {
            return res.redirect("/404");
          }
          if (req.query.error) {
            errors = [req.query.error];
          }
          return res.render("auth/change_password", {
            title: "Change Password - Coinnext.com",
            token: token,
            errors: errors
          });
        });
      });
    });
    app.post("/change-password", function(req, res) {
      var password, token;
      token = req.body.token;
      password = req.body.password;
      return UserToken.findByToken(token, function(err, userToken) {
        if (!userToken) {
          return res.redirect("/404");
        }
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
            if (err) {
              return JsonRenderer.error(err, res);
            }
            UserToken.invalidateByToken(token);
            res.writeHead(303, {
              "Location": "/login"
            });
            return res.end();
          });
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
        if (err) {
          return JsonRenderer.error(err, res);
        }
        return res.json({
          message: "The password was successfully changed."
        });
      });
    });
    app.get("/verify/:token", function(req, res) {
      var oldCsrf, oldStagingAuth, token;
      token = req.params.token;
      req.logout();
      oldStagingAuth = req.session.staging_auth;
      oldCsrf = req.session.csrfSecret;
      return req.session.regenerate(function() {
        req.session.staging_auth = oldStagingAuth;
        req.session.csrfSecret = oldCsrf;
        return UserToken.findByToken(token, function(err, userToken) {
          if (!userToken) {
            return res.redirect("/404");
          }
          return User.findByToken(token, function(err, user) {
            if (!user) {
              return res.redirect("/404");
            }
            return user.setEmailVerified(function(err, u) {
              res.render("auth/verify", {
                title: "Verify Account - Coinnext.com",
                user: u
              });
              return UserToken.invalidateByToken(token);
            });
          });
        });
      });
    });
    app.get("/resend", function(req, res) {
      var oldCsrf, oldStagingAuth, user;
      user = req.user;
      if (!user || user.email_verified) {
        return res.redirect("/404");
      }
      req.logout();
      oldStagingAuth = req.session.staging_auth;
      oldCsrf = req.session.csrfSecret;
      return req.session.regenerate(function() {
        req.session.staging_auth = oldStagingAuth;
        req.session.csrfSecret = oldCsrf;
        return UserToken.findEmailConfirmationToken(user.id, function(err, userToken) {
          if (!userToken) {
            return res.redirect("/404");
          }
          return User.findByToken(userToken.token, function(err, user) {
            if (!user) {
              return res.redirect("/404");
            }
            return user.sendEmailVerificationLink(function() {
              res.render("auth/resend_verify_link", {
                title: "Resend Verification Link - Coinnext.com",
                user: user
              });
              return UserToken.invalidateByToken(userToken.token);
            });
          });
        });
      });
    });
    app.post("/google_auth", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res, 401, false);
      }
      return res.json(UserToken.generateGAuthData());
    });
    app.put("/google_auth/:id?", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res, 401, false);
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
        return JsonRenderer.error(null, res, 401, false);
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
            var oldCsrf, oldSessionPassport, oldStagingAuth;
            if (googleToken && !googleToken.isValidGAuthPass(req.body.gauth_pass)) {
              req.logout();
              return JsonRenderer.error("Invalid Google Authenticator code", res, 401);
            }
            oldSessionPassport = req.session.passport;
            oldStagingAuth = req.session.staging_auth;
            oldCsrf = req.session.csrfSecret;
            return req.session.regenerate(function() {
              req.session.passport = oldSessionPassport;
              req.session.staging_auth = oldStagingAuth;
              req.session.csrfSecret = oldCsrf;
              res.json(JsonRenderer.user(req.user));
              return AuthStats.log({
                ip: req.ip,
                user: req.user
              }, req.user.email_auth_enabled && !req.user.recenltySignedUp());
            });
          });
        });
      })(req, res, next);
    };
  };

}).call(this);
