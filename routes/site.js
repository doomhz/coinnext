(function() {
  var AuthStats, JsonRenderer, MarketHelper, MarketStats, OrderLog, TradeStats, UserToken, Wallet, WalletHealth, _, _str;

  Wallet = GLOBAL.db.Wallet;

  WalletHealth = GLOBAL.db.WalletHealth;

  MarketStats = GLOBAL.db.MarketStats;

  TradeStats = GLOBAL.db.TradeStats;

  AuthStats = GLOBAL.db.AuthStats;

  UserToken = GLOBAL.db.UserToken;

  OrderLog = GLOBAL.db.OrderLog;

  JsonRenderer = require("../lib/json_renderer");

  MarketHelper = require("../lib/market_helper");

  _str = require("../lib/underscore_string");

  _ = require("underscore");

  module.exports = function(app) {
    app.get("/", function(req, res) {
      return MarketStats.getStats(function(err, marketStats) {
        return OrderLog.getNumberOfTrades(null, function(err, tradesCount) {
          return res.render("site/index", {
            title: req.user ? 'Home - Coinnext' : 'Coinnext - Cryptocurrency Exchange',
            page: "home",
            user: req.user,
            marketStats: JsonRenderer.marketStats(marketStats),
            currencies: MarketHelper.getCurrencyNames(),
            tradesCount: tradesCount,
            _str: _str
          });
        });
      });
    });
    app.get("/trade", function(req, res) {
      return res.redirect("/trade/LTC/BTC");
    });
    app.get("/trade/:currency1/:currency2", function(req, res) {
      var currency1, currency2;
      currency1 = req.params.currency1;
      currency2 = req.params.currency2;
      if (!MarketHelper.isValidCurrency(currency1) || !MarketHelper.isValidCurrency(currency2)) {
        return res.redirect("/");
      }
      return MarketStats.getStats(function(err, marketStats) {
        if (!marketStats["" + currency1 + "_" + currency2]) {
          return res.redirect("/404");
        }
        if (req.user) {
          return Wallet.findUserWalletByCurrency(req.user.id, currency1, function(err, wallet1) {
            if (!wallet1) {
              wallet1 = Wallet.build({
                currency: currency1
              });
            }
            return Wallet.findUserWalletByCurrency(req.user.id, currency2, function(err, wallet2) {
              if (!wallet2) {
                wallet2 = Wallet.build({
                  currency: currency2
                });
              }
              return res.render("site/trade", {
                title: "Trade " + (MarketHelper.getCurrencyName(currency1)) + " to " + (MarketHelper.getCurrencyName(currency2)) + " " + currency1 + "/" + currency2 + " - Coinnext",
                page: "trade",
                user: req.user,
                currency1: currency1,
                currency2: currency2,
                wallet1: wallet1,
                wallet2: wallet2,
                currencies: MarketHelper.getCurrencyNames(),
                marketStats: JsonRenderer.marketStats(marketStats),
                _str: _str
              });
            });
          });
        } else {
          return res.render("site/trade", {
            title: "Trade " + (MarketHelper.getCurrencyName(currency1)) + " to " + (MarketHelper.getCurrencyName(currency2)) + " " + currency1 + "/" + currency2 + " - Coinnext - Cryptocurrency Exchange",
            page: "trade",
            currency1: currency1,
            currency2: currency2,
            wallet1: Wallet.build({
              currency: currency1
            }),
            wallet2: Wallet.build({
              currency: currency2
            }),
            currencies: MarketHelper.getCurrencyNames(),
            marketStats: JsonRenderer.marketStats(marketStats),
            _str: _str
          });
        }
      });
    });
    app.get("/funds", function(req, res) {
      if (!req.user) {
        return res.redirect("/login");
      }
      return Wallet.findUserWallets(req.user.id, function(err, wallets) {
        if (wallets == null) {
          wallets = [];
        }
        return MarketStats.findRemovedCurrencies(function(err, removedCurrencies) {
          var currencies;
          wallets = wallets.filter(function(wl) {
            return removedCurrencies.indexOf(wl.currency) === -1;
          });
          currencies = MarketHelper.getSortedCurrencyNames();
          currencies = _.omit(currencies, removedCurrencies);
          return res.render("site/funds", {
            title: 'Funds - Coinnext',
            page: "funds",
            user: req.user,
            wallets: wallets,
            currencies: currencies,
            _str: _str
          });
        });
      });
    });
    app.get("/funds/:currency", function(req, res) {
      if (!req.user) {
        return res.redirect("/login");
      }
      return MarketStats.findRemovedCurrencies(function(err, removedCurrencies) {
        if (removedCurrencies.indexOf(req.params.currency) > -1) {
          return res.redirect("/404");
        }
        return Wallet.findUserWallets(req.user.id, function(err, wallets) {
          return Wallet.findUserWalletByCurrency(req.user.id, req.params.currency, function(err, wallet) {
            var currencies;
            if (err) {
              console.error(err);
            }
            if (!wallet) {
              return res.redirect("/");
            }
            wallets = wallets.filter(function(wl) {
              return removedCurrencies.indexOf(wl.currency) === -1;
            });
            currencies = MarketHelper.getSortedCurrencyNames();
            currencies = _.omit(currencies, removedCurrencies);
            return res.render("site/funds/wallet", {
              title: "" + req.params.currency + " - Funds - Coinnext",
              page: "funds",
              user: req.user,
              wallets: wallets,
              wallet: wallet,
              currencies: currencies,
              _str: _str
            });
          });
        });
      });
    });
    app.get("/market_stats", function(req, res) {
      return MarketStats.getStats(function(err, marketStats) {
        return res.json(JsonRenderer.marketStats(marketStats));
      });
    });
    app.get("/trade_stats/:market_type", function(req, res) {
      return TradeStats.getLastStats(req.params.market_type, function(err, tradeStats) {
        if (tradeStats == null) {
          tradeStats = [];
        }
        return res.json(JsonRenderer.tradeStats(tradeStats));
      });
    });
    app.get("/settings/preferences", function(req, res) {
      if (!req.user) {
        return res.redirect("/login");
      }
      return res.render("site/settings/preferences", {
        title: 'Preferences - Settings - Coinnext',
        page: 'settings',
        user: req.user
      });
    });
    app.get("/settings/security", function(req, res) {
      if (!req.user) {
        return res.redirect("/login");
      }
      return AuthStats.findByUser(req.user.id, function(err, authStats) {
        return UserToken.findByUserAndType(req.user.id, "google_auth", function(err, googleToken) {
          return res.render("site/settings/security", {
            title: 'Security - Settings - Coinnext',
            page: 'settings',
            user: req.user,
            authStats: authStats,
            googleToken: googleToken
          });
        });
      });
    });
    app.get("/status", function(req, res) {
      return WalletHealth.findAll().complete(function(err, wallets) {
        var sortedWallets;
        sortedWallets = _.sortBy(wallets, function(w) {
          return w.currency;
        });
        return res.render("site/status", {
          title: 'Status - Coinnext',
          page: "status",
          wallets: sortedWallets
        });
      });
    });
    app.get("/legal/terms", function(req, res) {
      return res.render("static/terms", {
        title: 'Terms - Coinnext',
        user: req.user
      });
    });
    app.get("/legal/privacy", function(req, res) {
      return res.render("static/privacy", {
        title: 'Privacy - Coinnext',
        user: req.user
      });
    });
    app.get("/legal/cookie", function(req, res) {
      return res.render("static/cookie", {
        title: 'Cookie - Coinnext',
        user: req.user
      });
    });
    app.get("/fees", function(req, res) {
      return res.render("static/fees", {
        title: 'Fees - Coinnext',
        user: req.user,
        MarketHelper: MarketHelper
      });
    });
    app.get("/security", function(req, res) {
      return res.render("static/security", {
        title: 'Security - Coinnext',
        user: req.user
      });
    });
    return app.get("/api", function(req, res) {
      return res.render("static/api", {
        title: 'API - Coinnext',
        user: req.user
      });
    });
  };

}).call(this);
