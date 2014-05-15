(function() {
  var JsonRenderer, User, Wallet;

  User = GLOBAL.db.User;

  Wallet = GLOBAL.db.Wallet;

  JsonRenderer = require('../lib/json_renderer');

  module.exports = function(app) {
    app.post("/user", function(req, res) {
      var data;
      data = {
        email: req.body.email,
        password: req.body.password
      };
      return User.createNewUser(data, function(err, newUser) {
        if (err) {
          return JsonRenderer.error(err, res);
        }
        newUser.sendEmailVerificationLink();
        Wallet.findOrCreateUserWalletByCurrency(newUser.id, "BTC");
        return res.json(JsonRenderer.user(newUser));
      });
    });
    app.get("/user/:id?", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res, 401, false);
      }
      return res.json(JsonRenderer.user(req.user));
    });
    return app.put("/user/:id?", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res, 401, false);
      }
      return req.user.updateSettings(req.body, function(err, user) {
        if (err) {
          return JsonRenderer.error(err, res);
        }
        return res.json(JsonRenderer.user(user));
      });
    });
  };

}).call(this);
