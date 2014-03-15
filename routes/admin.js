(function() {
  var JsonRenderer, User, Wallet, _, _str;

  Wallet = GLOBAL.db.Wallet;

  User = GLOBAL.db.User;

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
        page: "stats",
        user: req.user,
        _str: _str,
        _: _,
        currencies: Wallet.getCurrencies()
      });
    });
    app.get("/administratie/banksaldo/:currency", function(req, res) {
      var currency;
      currency = req.params.currency;
      if (GLOBAL.wallets[currency]) {
        return GLOBAL.wallets[currency].getBankBalance(function(err, balance) {
          if (err) {
            console.log(err);
          }
          return res.json({
            balance: balance || "wallet unaccessible",
            currency: currency
          });
        });
      } else {
        return res.json({
          balance: "wallet unaccessible",
          currency: currency
        });
      }
    });
    app.post("/administratie/wallet_info", function(req, res) {
      var currency;
      currency = req.body.currency;
      if (GLOBAL.wallets[currency]) {
        return GLOBAL.wallets[currency].getInfo(function(err, info) {
          if (err) {
            console.log(err);
          }
          return res.json({
            info: info || "wallet unaccessible",
            currency: currency,
            address: GLOBAL.appConfig().wallets[currency.toLowerCase()].wallet.address
          });
        });
      } else {
        return res.json({
          info: "wallet unaccessible",
          currency: currency
        });
      }
    });
    app.post("/administratie/search_user", function(req, res) {
      var renderUser, term;
      term = req.body.term;
      renderUser = function(err, user) {
        if (user == null) {
          user = {};
        }
        return res.json(user);
      };
      if (_.isNumber(parseInt(term))) {
        return User.findById(term, renderUser);
      }
      if (term.indexOf("@") > -1) {
        return User.findByEmail(term, renderUser);
      }
      return Wallet.findByAddress(term, function(err, wallet) {
        if (wallet) {
          return User.findById(wallet.user_id, renderUser);
        }
        return res.json({
          error: "Could not find user by " + term
        });
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
