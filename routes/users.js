(function() {
  var JsonRenderer, User, Wallet;

  User = require('../models/user');

  Wallet = require('../models/wallet');

  JsonRenderer = require('../lib/json_renderer');

  module.exports = function(app) {
    var login;
    app.post("/user", function(req, res) {
      var user;
      user = new User({
        email: req.body.email,
        password: User.hashPassword(req.body.password)
      });
      return user.save(function(err, newUser) {
        if (err) {
          return JsonRenderer.error(err, res);
        }
        newUser.generateToken(function() {
          newUser.sendEmailVerificationLink();
          return Wallet.findOrCreateUserWalletByCurrency(newUser.id, "BTC");
        });
        return res.json(JsonRenderer.user(newUser));
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
        return JsonRenderer.error(null, res);
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
        return JsonRenderer.error(null, res);
      }
      return req.user.generateGAuthData(function() {
        return res.json(JsonRenderer.user(req.user));
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
          if (user.gauth_data && !user.isValidGAuthPass(req.body.gauth_pass)) {
            req.logout();
            return JsonRenderer.error("Invalid Google Authenticator code", res, 401);
          }
          return res.json(JsonRenderer.user(req.user));
        });
      })(req, res, next);
    };
  };

}).call(this);
