(function() {
  var Wallet;

  Wallet = require("../models/wallet");

  module.exports = function(app) {
    app.get("/", function(req, res) {
      return res.render("site/index", {
        title: 'Home',
        user: req.user
      });
    });
    app.get("/trade", function(req, res) {
      return res.redirect("/trade/BTC/LTC");
    });
    app.get("/trade/:currency1/:currency2", function(req, res) {
      var currencies, currency1, currency2;
      currency1 = req.params.currency1;
      currency2 = req.params.currency2;
      currencies = Wallet.getCurrencies();
      if (currencies.indexOf(currency1) === -1 || currencies.indexOf(currency2) === -1) {
        return res.redirect("/");
      }
      return Wallet.findUserWalletByCurrency(req.user.id, currency1, function(err, wallet1) {
        return Wallet.findUserWalletByCurrency(req.user.id, currency2, function(err, wallet2) {
          if (!wallet1 || !wallet2) {
            res.redirect("/funds");
          }
          return res.render("site/trade", {
            title: 'Trade #{currency1} to #{currency2}',
            user: req.user,
            wallet1: wallet1,
            wallet2: wallet2,
            currencies: Wallet.getCurrencyNames()
          });
        });
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
    app.get("/settings", function(req, res) {
      return res.render("site/settings/settings", {
        title: 'Settings',
        page: 'Settings',
        user: req.user
      });
    });
    app.get("/settings/preferences", function(req, res) {
      return res.render("site/settings/preferences", {
        title: 'Preferencs - Settings',
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
