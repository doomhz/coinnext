(function() {
  var Wallet, _;

  Wallet = require("../models/wallet");

  _ = require("underscore");

  module.exports = function(app) {
    var renderError;
    app.post("/wallets", function(req, res) {
      var currency;
      currency = req.body.currency;
      console.log(currency);
      console.log(req.body);
      if (req.user) {
        return Wallet.findUserWalletByCurrency(req.user.id, currency, function(err, wallet) {
          if (!wallet) {
            wallet = new Wallet({
              user_id: req.user.id,
              currency: currency
            });
            return wallet.save(function(err, wl) {
              if (err) {
                return renderError("Sorry, can not create a wallet at this time...", res);
              }
              return res.json(wl);
            });
          } else {
            return renderError("A wallet of this currency already exists.", res);
          }
        });
      }
    });
    app.get("/wallets", function(req, res) {
      if (req.user) {
        return Wallet.findUserWallets(req.user.id, function(err, wallets) {
          if (err) {
            console.error(err);
          }
          return res.json(wallets);
        });
      }
    });
    return renderError = function(err, res, code) {
      var key, message, val, _ref;
      if (code == null) {
        code = 409;
      }
      res.statusCode = code;
      message = "";
      if (_.isString(err)) {
        message = err;
      } else if (_.isObject(err) && err.name === "ValidationError") {
        _ref = err.errors;
        for (key in _ref) {
          val = _ref[key];
          if (val.path === "email" && val.message === "unique") {
            message += "E-mail is already taken. ";
          } else {
            message += "" + val.message + " ";
          }
        }
      }
      return res.json({
        error: message
      });
    };
  };

}).call(this);
