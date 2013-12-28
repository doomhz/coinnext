(function() {
  var Wallet, restify;

  restify = require("restify");

  Wallet = require("../../models/wallet");

  module.exports = function(app) {
    return app.post("/create_account/:account/:currency", function(req, res, next) {
      var account, currency;
      account = req.params.account;
      currency = req.params.currency;
      if (GLOBAL.wallets[currency]) {
        return GLOBAL.wallets[currency].generateAddress(account, function(err, address) {
          if (!err) {
            return res.send({
              account: account,
              address: address
            });
          } else {
            return next(new restify.ConflictError("Could not generate address."));
          }
        });
      } else {
        return next(new restify.ConflictError("Wrong Currency."));
      }
    });
  };

}).call(this);
