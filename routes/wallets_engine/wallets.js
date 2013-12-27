(function() {
  var Wallet, restify;

  restify = require("restify");

  Wallet = require("../../models/wallet");

  module.exports = function(app) {
    return app.post("/create_account/:user_id/:currency", function(req, res, next) {
      var currency, userId;
      userId = req.params.user_id;
      currency = req.params.currency;
      if (GLOBAL.wallets[currency]) {
        return GLOBAL.wallets[currency].generateAddress(userId, function(err, address) {
          if (!err) {
            return res.send({
              account: userId,
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
