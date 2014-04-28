(function() {
  var AuthStats, JsonRenderer, MarketHelper, MarketStats, TradeStats, UserToken, Wallet, _str;

  Wallet = GLOBAL.db.Wallet;

  MarketStats = GLOBAL.db.MarketStats;

  TradeStats = GLOBAL.db.TradeStats;

  AuthStats = GLOBAL.db.AuthStats;

  UserToken = GLOBAL.db.UserToken;

  JsonRenderer = require("../lib/json_renderer");

  MarketHelper = require("../lib/market_helper");

  _str = require("../lib/underscore_string");

  module.exports = function(app) {
    app.get("/", function(req, res) {
      return MarketStats.getStats(function(err, marketStats) {
        return res.render("site/index", {
          title: 'Home',
          page: "home",
          user: req.user,
          marketStats: JsonRenderer.marketStats(marketStats),
          currencies: MarketHelper.getCurrencyNames()
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
                title: "Trade " + currency1 + " to " + currency2,
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
            title: "Trade " + currency1 + " to " + currency2,
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
        return res.render("site/funds", {
          title: 'Funds',
          page: "funds",
          user: req.user,
          wallets: wallets,
          currencies: MarketHelper.getCurrencyNames(),
          _str: _str
        });
      });
    });
    app.get("/funds/:currency", function(req, res) {
      if (!req.user) {
        return res.redirect("/login");
      }
      return Wallet.findUserWallets(req.user.id, function(err, wallets) {
        return Wallet.findUserWalletByCurrency(req.user.id, req.params.currency, function(err, wallet) {
          if (err) {
            console.error(err);
          }
          if (!wallet) {
            return res.redirect("/");
          }
          return res.render("site/funds/wallet", {
            title: 'Wallet overview',
            page: "funds",
            user: req.user,
            wallet: wallet,
            wallets: wallets,
            currencies: MarketHelper.getCurrencyNames(),
            _str: _str
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
    app.get("/settings", function(req, res) {
      if (!req.user) {
        return res.redirect("/login");
      }
      return res.render("site/settings/settings", {
        title: 'Settings',
        page: 'settings',
        user: req.user
      });
    });
    app.get("/settings/preferences", function(req, res) {
      if (!req.user) {
        return res.redirect("/login");
      }
      return res.render("site/settings/preferences", {
        title: 'Preferences - Settings',
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
            title: 'Security - Settings',
            page: 'settings',
            user: req.user,
            authStats: authStats,
            googleToken: googleToken
          });
        });
      });
    });
    app.get("/legal/terms", function(req, res) {
      return res.render("static/terms", {
        title: 'Terms',
        user: req.user
      });
    });
    app.get("/legal/privacy", function(req, res) {
      return res.render("static/privacy", {
        title: 'Privacy',
        user: req.user
      });
    });
    app.get("/legal/cookie", function(req, res) {
      return res.render("static/cookie", {
        title: 'Cookie',
        user: req.user
      });
    });
    app.get("/fees", function(req, res) {
      return res.render("static/fees", {
        title: 'Fees',
        user: req.user
      });
    });
    app.get("/about", function(req, res) {
      return res.render("static/about", {
        title: 'About',
        user: req.user
      });
    });
    app.get("/security", function(req, res) {
      return res.render("static/security", {
        title: 'Security',
        user: req.user
      });
    });
    return app.get("/whitehat", function(req, res) {
      return res.render("static/whitehat", {
        title: 'White Hat',
        user: req.user
      });
    });
  };

}).call(this);
