(function() {
  var JsonRenderer, exports, _;

  _ = require("underscore");

  JsonRenderer = {
    user: function(user) {
      return {
        id: user.id,
        email: user.email,
        username: user.email.substr(0, user.email.indexOf("@")),
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
        hold_balance: wallet.hold_balance,
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
        transaction_id: payment.transaction_id,
        address: payment.address,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        updated: payment.updated,
        created: payment.created
      };
    },
    payments: function(payments) {
      var data, payment, _i, _len;
      data = [];
      for (_i = 0, _len = payments.length; _i < _len; _i++) {
        payment = payments[_i];
        data.push(this.payment(payment));
      }
      return data;
    },
    transaction: function(transaction) {
      return {
        id: transaction.id,
        user_id: transaction.user_id,
        wallet_id: transaction.wallet_id,
        currency: transaction.currency,
        fee: transaction.fee,
        address: transaction.address,
        amount: transaction.amount,
        category: transaction.category,
        txid: transaction.txid,
        confirmations: transaction.confirmations,
        created: transaction.created
      };
    },
    transactions: function(transactions) {
      var data, transaction, _i, _len;
      data = [];
      for (_i = 0, _len = transactions.length; _i < _len; _i++) {
        transaction = transactions[_i];
        data.push(this.transaction(transaction));
      }
      return data;
    },
    order: function(order) {
      return {
        id: order.id,
        user_id: order.user_id,
        type: order.type,
        action: order.action,
        buy_currency: order.buy_currency,
        sell_currency: order.sell_currency,
        amount: order.amount,
        sold_amount: order.sold_amount,
        result_amount: order.result_amount,
        fee: order.fee,
        unit_price: order.unit_price,
        status: order.status,
        published: order.published,
        created: order.created
      };
    },
    orders: function(orders) {
      var data, order, _i, _len;
      data = [];
      for (_i = 0, _len = orders.length; _i < _len; _i++) {
        order = orders[_i];
        data.push(this.order(order));
      }
      return data;
    },
    error: function(err, res, code, log) {
      var key, message, val, _ref;
      if (code == null) {
        code = 409;
      }
      if (log == null) {
        log = true;
      }
      res.statusCode = code;
      message = "";
      if (_.isString(err)) {
        message = err;
      } else if (_.isObject(err) && err.name === "ValidationError") {
        _ref = err.errors;
        for (key in _ref) {
          val = _ref[key];
          if (val.path === "email" && val.type === "user defined") {
            message += "E-mail is already taken. ";
          } else {
            message += "" + val.message + " ";
          }
        }
      }
      res.json({
        error: message
      });
      if (log) {
        return console.error(message);
      }
    }
  };

  exports = module.exports = JsonRenderer;

}).call(this);
