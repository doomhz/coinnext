(function() {
  var JsonRenderer, _, _str;

  JsonRenderer = require("../lib/json_renderer");

  _ = require("underscore");

  _str = require("../lib/underscore_string");

  module.exports = function(app) {
    var login;
    app.get("/administratie/login", function(req, res, next) {
      return res.render("admin/login");
    });
    app.post("/administratie/login", function(req, res, next) {
      return login(req, res, next);
    });
    app.get("/administratie/logout", function(req, res, next) {
      req.logout();
      return res.redirect("/administratie");
    });
    app.get("/administratie*", function(req, res, next) {
      if (!req.user) {
        res.redirect("/administratie/login");
      }
      return next();
    });
    app.get("/administratie", function(req, res) {
      return res.render("admin/stats", {
        title: "Stats - Admin - Satoshibet",
        btcBankAddress: GLOBAL.wallets["BTC"].address,
        ppcBankAddress: GLOBAL.wallets["PPC"].address,
        ltcBankAddress: GLOBAL.wallets["LTC"].address,
        _str: _str,
        _: _
      });
    });
    app.get("/administratie/banksaldo", function(req, res) {
      return res.json({
        btcBankBalance: 0,
        ppcBankBalance: 0,
        ltcBankBalance: 0
      });
    });
    return login = function(req, res, next) {
      return passport.authenticate("local", function(err, user, info) {
        if (err) {
          return res.redirect("/administratie/login");
        }
        if (!user) {
          return res.redirect("/administratie/login");
        }
        return req.logIn(user, function(err) {
          if (err) {
            return res.redirect("/administratie/login");
          }
          if (user.gauth_data && !user.isValidGAuthPass(req.body.gauth_pass)) {
            req.logout();
            return res.redirect("/administratie/login");
          }
          return res.redirect("/administratie");
        });
      })(req, res, next);
    };
  };

}).call(this);
