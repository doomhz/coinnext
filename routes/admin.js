(function() {
  var AuthStats, JsonRenderer, MarketHelper, MarketStats, Payment, Transaction, User, Wallet, jsonBeautifier, _, _str;

  Wallet = GLOBAL.db.Wallet;

  User = GLOBAL.db.User;

  Transaction = GLOBAL.db.Transaction;

  Payment = GLOBAL.db.Payment;

  AuthStats = GLOBAL.db.AuthStats;

  MarketStats = GLOBAL.db.MarketStats;

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
        title: "Stats - Admin - CoinNext",
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
          title: "Users - Admin - CoinNext",
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
              title: "User " + user.email + " - " + user.id + " - Admin - CoinNext",
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
          title: "Wallet " + wallet.id + " - Admin - CoinNext",
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
          currency: MarketHelper.getCurrency(currency)
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
          title: "Wallets - Admin - CoinNext",
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
          title: "Transactions - Admin - CoinNext",
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
        include: [
          {
            model: GLOBAL.db.PaymentLog
          }
        ],
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
          title: "Payments - Admin - CoinNext",
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
          if (body && (body.paymentId != null)) {
            return Payment.findById(id, function(err, payment) {
              if (!payment.isProcessed()) {
                return JsonRenderer.error("Could not process payment - " + (JSON.stringify(body)), res);
              }
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
    app.del("/administratie/payment/:id", function(req, res) {
      var id;
      id = req.params.id;
      return Payment.destroy({
        id: id,
        status: MarketHelper.getPaymentStatus("pending")
      }).complete(function(err, payment) {
        if (err) {
          return JsonRenderer.error(err, res);
        }
        return res.json(JsonRenderer.payment({
          status: "removed"
        }));
      });
    });
    app.post("/administratie/clear_pending_payments", function(req, res) {
      return Payment.destroy({
        status: MarketHelper.getPaymentStatus("pending")
      }).complete(function(err, payment) {
        return res.json({});
      });
    });
    app.get("/administratie/banksaldo/:currency", function(req, res) {
      var currency;
      currency = req.params.currency;
      return GLOBAL.walletsClient.send("wallet_balance", [currency], (function(_this) {
        return function(err, res2, body) {
          if (err) {
            return JsonRenderer.error(err, res);
          }
          if (body && (body.balance != null)) {
            return res.json(body);
          } else {
            return res.json({
              currency: currency,
              balance: "wallet error"
            });
          }
        };
      })(this));
    });
    app.post("/administratie/wallet_info", function(req, res) {
      var currency;
      currency = req.body.currency;
      return GLOBAL.walletsClient.send("wallet_info", [currency], (function(_this) {
        return function(err, res2, body) {
          if (err) {
            return JsonRenderer.error(err, res);
          }
          if (body && (body.info != null)) {
            return res.json(body);
          } else {
            return res.json({
              currency: currency,
              info: "wallet error"
            });
          }
        };
      })(this));
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
    app.get("/administratie/markets", function(req, res) {
      return MarketStats.getStats(function(err, markets) {
        return res.render("admin/markets", {
          title: "Markets - Admin - CoinNext",
          page: "markets",
          adminUser: req.user,
          _str: _str,
          _: _,
          currencies: MarketHelper.getCurrencyTypes(),
          markets: markets
        });
      });
    });
    app.put("/administratie/markets/:id", function(req, res) {
      return MarketStats.setMarketStatus(req.params.id, req.body.status, function(err, market) {
        if (err) {
          console.error(err);
        }
        return res.json(market);
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
          if (process.env.NODE_ENV === "production") {
            if (user.gauth_key && !user.isValidGAuthPass(req.body.gauth_pass)) {
              req.logout();
              return res.redirect("/administratie/login");
            }
          }
          return res.redirect("/administratie");
        });
      })(req, res, next);
    };
  };

}).call(this);
