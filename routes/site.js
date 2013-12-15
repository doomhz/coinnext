(function() {
  var speakeasy;

  speakeasy = require("speakeasy");

  module.exports = function(app) {
    app.get("/", function(req, res) {
      return res.render("site/index", {
        title: 'Home',
        user: req.user
      });
    });
    app.get("/signup", function(req, res) {
      return res.render("site/signup");
    });
    app.get("/login", function(req, res) {
      return res.render("site/login");
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
        user: req.user
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
