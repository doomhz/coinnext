(function() {
  var JsonRenderer, exports, _;

  _ = require("underscore");

  JsonRenderer = {
    user: function(user) {
      return {
        id: user.id,
        email: user.email,
        created: user.created,
        gauth_data: user.gauth_data
      };
    },
    wallet: function(wallet) {
      return {
        id: wallet.id,
        user_id: wallet.user_id,
        currency: wallet.currency,
        balance: wallet.balance,
        address: wallet.address,
        created: wallet.created
      };
    },
    wallets: function(wallets) {
      var data, wallet, _i, _len;
      data = [];
      for (_i = 0, _len = wallets.length; _i < _len; _i++) {
        wallet = wallets[_i];
        data.push(this.wallet(wallet));
      }
      return data;
    },
    payment: function(payment) {
      return {
        id: payment.id,
        user_id: payment.user_id,
        wallet_id: payment.wallet_id,
        address: payment.address,
        amount: payment.amount,
        status: payment.status,
        updated: payment.updated,
        created: payment.created
      };
    },
    error: function(err, res, code) {
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
    }
  };

  exports = module.exports = JsonRenderer;

}).call(this);
