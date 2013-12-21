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
      return res.render("site/trade", {
        title: 'Trade',
        user: req.user
      });
    });
    app.get("/finances", function(req, res) {
      return res.render("site/finances", {
        title: 'Finances',
        user: req.user,
        currencies: Wallet.getCurrencies()
      });
    });
    return app.get("/settings", function(req, res) {
      return res.render("site/settings", {
        title: 'Settings',
        user: req.user
      });
    });
  };

}).call(this);
