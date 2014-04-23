(function() {
  var JsonRenderer, exports, _, _str;

  _ = require("underscore");

  _str = require("underscore.string");

  JsonRenderer = {
    user: function(user) {
      return {
        id: user.uuid,
        email: user.email,
        username: user.username,
        gauth_qr: user.gauth_qr,
        gauth_key: user.gauth_key,
        chat_enabled: user.chat_enabled,
        email_auth_enabled: user.email_auth_enabled,
        updated_at: user.updated_at,
        created_at: user.created_at
      };
    },
    wallet: function(wallet) {
      return {
        id: wallet.id,
        currency: wallet.currency,
        balance: wallet.balance,
        hold_balance: wallet.hold_balance,
        address: wallet.address,
        updated_at: wallet.updated_at,
        created_at: wallet.created_at
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
        wallet_id: payment.wallet_id,
        transaction_id: payment.transaction_id,
        address: payment.address,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        updated_at: payment.updated_at,
        created_at: payment.created_at
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
        wallet_id: transaction.wallet_id,
        currency: transaction.currency,
        fee: transaction.fee,
        address: transaction.address,
        amount: transaction.amount,
        category: transaction.category,
        txid: transaction.txid,
        confirmations: transaction.confirmations,
        balance_loaded: transaction.balance_loaded,
        updated_at: transaction.updated_at,
        created_at: transaction.created_at
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
        type: order.type,
        action: order.action,
        buy_currency: order.buy_currency,
        sell_currency: order.sell_currency,
        amount: order.amount,
        matched_amount: order.matched_amount,
        result_amount: order.result_amount,
        fee: order.fee,
        unit_price: order.unit_price,
        status: order.status,
        published: order.published,
        updated_at: order.updated_at,
        created_at: order.created_at
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
    chatMessage: function(message, user) {
      var data, username;
      if (user == null) {
        user = {};
      }
      username = user.username;
      if (message.user != null) {
        username = message.user.username;
      }
      return data = {
        id: message.id,
        message: message.message,
        created_at: message.created_at,
        updated_at: message.updated_at,
        username: username
      };
    },
    chatMessages: function(messages) {
      var data, message, _i, _len;
      data = [];
      for (_i = 0, _len = messages.length; _i < _len; _i++) {
        message = messages[_i];
        data.push(this.chatMessage(message));
      }
      return data;
    },
    error: function(err, res, code, log) {
      var key, message, val;
      if (code == null) {
        code = 409;
      }
      if (log == null) {
        log = true;
      }
      if (log) {
        console.error(err);
      }
      res.statusCode = code;
      if (_.isObject(err)) {
        delete err.sql;
        if (err.code === "ER_DUP_ENTRY") {
          return res.json({
            error: this.formatDuplicateError("" + err)
          });
        }
      }
      message = "";
      if (_.isString(err)) {
        message = err;
      } else if (_.isObject(err)) {
        for (key in err) {
          val = err[key];
          if (_.isArray(val)) {
            message += "" + (val.join(' ')) + " ";
          } else {
            message += "" + val + " ";
          }
        }
      }
      return res.json({
        error: this.formatDuplicateError(message)
      });
    },
    formatDuplicateError: function(message) {
      message = message.replace("Error: ER_DUP_ENTRY: ", "");
      message = message.replace(/for key.*$/, "");
      message = message.replace(/Duplicate entry/, "Value already taken");
      return _str.trim(message);
    }
  };

  exports = module.exports = JsonRenderer;

}).call(this);
