(function() {
  var MarketStats, Wallet;

  Wallet = require("../models/wallet");

  MarketStats = require("../models/market_stats");

  module.exports = function(app) {
    app.get("/", function(req, res) {
      return MarketStats.getStats(function(err, marketStats) {
        return res.render("site/index", {
          title: 'Home',
          user: req.user,
          marketStats: marketStats,
          currencies: Wallet.getCurrencyNames()
        });
      });
    });
    app.get("/trade", function(req, res) {
      return res.redirect("/trade/LTC/BTC");
    });
    app.get("/trade/:currency1/:currency2", function(req, res) {
      var currencies, currency1, currency2;
      currency1 = req.params.currency1;
      currency2 = req.params.currency2;
      currencies = Wallet.getCurrencies();
      if (currencies.indexOf(currency1) === -1 || currencies.indexOf(currency2) === -1) {
        return res.redirect("/");
      }
      return MarketStats.getStats(function(err, marketStats) {
        if (req.user) {
          return Wallet.findUserWalletByCurrency(req.user.id, currency1, function(err, wallet1) {
            if (!wallet1) {
              wallet1 = new Wallet({
                currency: currency1
              });
            }
            return Wallet.findUserWalletByCurrency(req.user.id, currency2, function(err, wallet2) {
              if (!wallet2) {
                wallet2 = new Wallet({
                  currency: currency2
                });
              }
              return res.render("site/trade", {
                title: "Trade " + currency1 + " to " + currency2,
                user: req.user,
                currency1: currency1,
                currency2: currency2,
                wallet1: wallet1,
                wallet2: wallet2,
                currencies: Wallet.getCurrencyNames(),
                marketStats: marketStats
              });
            });
          });
        } else {
          return res.render("site/trade", {
            title: "Trade " + currency1 + " to " + currency2,
            currency1: currency1,
            currency2: currency2,
            wallet1: new Wallet({
              currency: currency1
            }),
            wallet2: new Wallet({
              currency: currency2
            }),
            currencies: Wallet.getCurrencyNames(),
            marketStats: marketStats
          });
        }
      });
    });
    app.get("/funds", function(req, res) {
      return Wallet.findUserWallets(req.user.id, function(err, wallets) {
        return res.render("site/funds", {
          title: 'Funds',
          user: req.user,
          wallets: wallets,
          currencies: Wallet.getCurrencyNames()
        });
      });
    });
    app.get("/funds/:currency", function(req, res) {
      return Wallet.findUserWallets(req.user.id, function(err, wallets) {
        return Wallet.findUserWalletByCurrency(req.user.id, req.params.currency, function(err, wallet) {
          if (err) {
            console.error(err);
          }
          if (wallet) {
            return res.render("site/funds/wallet", {
              title: 'Wallet overview',
              user: req.user,
              wallet: wallet,
              wallets: wallets,
              currencies: Wallet.getCurrencyNames()
            });
          } else {
            return res.redirect("/");
          }
        });
      });
    });
    app.get("/market_stats", function(req, res) {
      return MarketStats.getStats(function(err, marketStats) {
        return res.json(marketStats);
      });
    });
    app.get("/settings", function(req, res) {
      return res.render("site/settings/settings", {
        title: 'Settings',
        page: 'Settings',
        user: req.user
      });
    });
    app.get("/settings/preferences", function(req, res) {
      return res.render("site/settings/preferences", {
        title: 'Preferences - Settings',
        page: 'Settings',
        user: req.user
      });
    });
    app.get("/settings/security", function(req, res) {
      return res.render("site/settings/security", {
        title: 'Security - Settings',
        page: 'Settings',
        user: req.user
      });
    });
    app.get("/legal/terms", function(req, res) {
      return res.render("static/terms", {
        title: 'Terms'
      });
    });
    app.get("/legal/privacy", function(req, res) {
      return res.render("static/privacy", {
        title: 'Privacy'
      });
    });
    app.get("/legal/cookie", function(req, res) {
      return res.render("static/cookie", {
        title: 'Cookie'
      });
    });
    app.get("/fees", function(req, res) {
      return res.render("static/fees", {
        title: 'Fees'
      });
    });
    return app.get("/company", function(req, res) {
      return res.render("static/company", {
        title: 'Company'
      });
    });
  };

}).call(this);
