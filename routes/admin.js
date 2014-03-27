(function() {
  var AuthStats, JsonRenderer, MarketHelper, Payment, Transaction, User, Wallet, jsonBeautifier, _, _str;

  Wallet = GLOBAL.db.Wallet;

  User = GLOBAL.db.User;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  AuthStats = GLOBAL.db.AuthStats;

  MarketHelper = require("../lib/market_helper");

  JsonRenderer = require("../lib/json_renderer");

  jsonBeautifier = require("../lib/json_beautifier");

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
        adminUser: req.user,
        _str: _str,
        _: _,
        currencies: MarketHelper.getCurrencyTypes()
      });
    });
    app.get("/administratie/users", function(req, res) {
      var count, from, query;
      count = req.query.count || 20;
      from = req.query.from != null ? parseInt(req.query.from) : 0;
      query = {
        order: [["updated_at", "DESC"]],
        limit: count,
        offset: from
      };
      return User.findAndCountAll(query).complete(function(err, result) {
        if (result == null) {
          result = {
            rows: [],
            count: 0
          };
        }
        return res.render("admin/users", {
          title: "Users - Admin - Satoshibet",
          page: "users",
          adminUser: req.user,
          _str: _str,
          _: _,
          currencies: MarketHelper.getCurrencyTypes(),
          users: result.rows,
          totalUsers: result.count,
          from: from,
          count: count
        });
      });
    });
    app.get("/administratie/user/:id", function(req, res) {
      return User.findById(req.params.id, function(err, user) {
        return Wallet.findAll({
          where: {
            user_id: req.params.id
          }
        }).complete(function(err, wallets) {
          var query;
          query = {
            where: {
              user_id: req.params.id
            },
            order: [["created_at", "DESC"]],
            limit: 20
          };
          return AuthStats.findAll(query).complete(function(err, authStats) {
            return res.render("admin/user", {
              title: "User " + user.email + " - " + user.id + " - Admin - Satoshibet",
              page: "users",
              adminUser: req.user,
              _str: _str,
              _: _,
              currencies: MarketHelper.getCurrencyTypes(),
              user: user,
              wallets: wallets,
              authStats: authStats
            });
          });
        });
      });
    });
    app.get("/administratie/wallet/:id", function(req, res) {
      return Wallet.findById(req.params.id, function(err, wallet) {
        return res.render("admin/wallet", {
          title: "Wallet " + wallet.id + " - Admin - Satoshibet",
          page: "wallets",
          adminUser: req.user,
          _str: _str,
          _: _,
          currencies: MarketHelper.getCurrencyTypes(),
          wallet: wallet
        });
      });
    });
    app.get("/administratie/wallets", function(req, res) {
      var count, currency, from, query;
      count = req.query.count || 20;
      from = req.query.from != null ? parseInt(req.query.from) : 0;
      currency = req.query.currency != null ? req.query.currency : "BTC";
      query = {
        where: {
          currency: currency
        },
        order: [["balance", "DESC"]],
        limit: count,
        offset: from
      };
      return Wallet.findAndCountAll(query).complete(function(err, result) {
        if (result == null) {
          result = {
            rows: [],
            count: 0
          };
        }
        return res.render("admin/wallets", {
          title: "Wallets - Admin - Satoshibet",
          page: "wallets",
          adminUser: req.user,
          _str: _str,
          _: _,
          currencies: MarketHelper.getCurrencyTypes(),
          wallets: result.rows,
          totalWallets: result.count,
          from: from,
          count: count,
          currency: currency
        });
      });
    });
    app.get("/administratie/transactions", function(req, res) {
      var count, from, query, userId;
      userId = req.query.user_id || "";
      count = req.query.count || 20;
      from = req.query.from != null ? parseInt(req.query.from) : 0;
      query = {
        order: [["created_at", "DESC"]],
        limit: count,
        offset: from
      };
      if (userId) {
        query.where = {
          user_id: userId
        };
      }
      return Transaction.findAndCountAll(query).complete(function(err, result) {
        if (result == null) {
          result = {
            rows: [],
            count: 0
          };
        }
        return res.render("admin/transactions", {
          title: "Transactions - Admin - Satoshibet",
          page: "transactions",
          adminUser: req.user,
          _str: _str,
          _: _,
          currencies: MarketHelper.getCurrencyTypes(),
          transactions: result.rows,
          totalTransactions: result.count,
          from: from,
          count: count,
          jsonBeautifier: jsonBeautifier
        });
      });
    });
    app.get("/administratie/payments", function(req, res) {
      var count, from, query, userId;
      userId = req.query.user_id || "";
      count = req.query.count || 20;
      from = req.query.from != null ? parseInt(req.query.from) : 0;
      query = {
        order: [["created_at", "DESC"]],
        limit: count,
        offset: from
      };
      if (userId) {
        query.where = {
          user_id: userId
        };
      }
      return Payment.findAndCountAll(query).complete(function(err, result) {
        if (result == null) {
          result = {
            rows: [],
            count: 0
          };
        }
        return res.render("admin/payments", {
          title: "Payments - Admin - Satoshibet",
          page: "payments",
          adminUser: req.user,
          _str: _str,
          _: _,
          currencies: MarketHelper.getCurrencyTypes(),
          payments: result.rows,
          totalPayments: result.count,
          from: from,
          count: count,
          jsonBeautifier: jsonBeautifier
        });
      });
    });
    app.put("/administratie/pay/:id", function(req, res) {
      var id;
      id = req.params.id;
      return GLOBAL.walletsClient.send("process_payment", [id], (function(_this) {
        return function(err, res2, body) {
          if (err) {
            return JsonRenderer.error(err, res);
          }
          if (body && body.paymentId) {
            return Payment.findById(id, function(err, payment) {
              if (err) {
                return JsonRenderer.error(err, res);
              }
              return res.json(JsonRenderer.payment(payment));
            });
          } else {
            return JsonRenderer.error("Could not process payment - " + (JSON.stringify(body)), res);
          }
        };
      })(this));
    });
    app.post("/administratie/clear_pending_payments", function(req, res) {
      return Payment.destroy({
        status: "pending"
      }).complete(function(err, payment) {
        return res.json({});
      });
    });
    app.get("/administratie/banksaldo/:currency", function(req, res) {
      var currency;
      currency = req.params.currency;
      if (GLOBAL.wallets[currency]) {
        return GLOBAL.wallets[currency].getBankBalance(function(err, balance) {
          if (balance == null) {
            balance = "wallet unaccessible";
          }
          if (err) {
            console.log(err);
          }
          return res.json({
            balance: balance,
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
          if (user.gauth_key && !user.isValidGAuthPass(req.body.gauth_pass)) {
            req.logout();
            return res.redirect("/administratie/login");
          }
          return res.redirect("/administratie");
        });
      })(req, res, next);
    };
  };

}).call(this);
