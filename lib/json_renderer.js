(function() {
  var JsonRenderer, MarketHelper, exports, _, _str;

  MarketHelper = require("./market_helper");

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
        balance: wallet.getFloat("balance"),
        hold_balance: wallet.getFloat("hold_balance"),
        address: wallet.address,
        min_confirmations: wallet.network_confirmations,
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
        amount: payment.getFloat("amount"),
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
        fee: transaction.getFloat("fee"),
        address: transaction.address,
        amount: transaction.getFloat("amount"),
        category: transaction.category,
        txid: transaction.txid,
        confirmations: transaction.confirmations,
        min_confirmations: transaction.network_confirmations,
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
        amount: order.getFloat("amount"),
        matched_amount: order.getFloat("matched_amount"),
        result_amount: order.getFloat("result_amount"),
        fee: order.getFloat("fee"),
        unit_price: order.getFloat("unit_price"),
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
    marketStats: function(marketStats) {
      var stats, type;
      for (type in marketStats) {
        stats = marketStats[type];
        stats.last_price = MarketHelper.fromBigint(stats.last_price);
        stats.day_high = MarketHelper.fromBigint(stats.day_high);
        stats.day_low = MarketHelper.fromBigint(stats.day_low);
        stats.volume1 = MarketHelper.fromBigint(stats.volume1);
        stats.volume2 = MarketHelper.fromBigint(stats.volume2);
        stats.growth_ratio = MarketHelper.fromBigint(stats.growth_ratio);
      }
      return marketStats;
    },
    tradeStats: function(tradeStats) {
      var stats, _i, _len;
      for (_i = 0, _len = tradeStats.length; _i < _len; _i++) {
        stats = tradeStats[_i];
        stats.open_price = MarketHelper.fromBigint(stats.open_price);
        stats.close_price = MarketHelper.fromBigint(stats.close_price);
        stats.high_price = MarketHelper.fromBigint(stats.high_price);
        stats.low_price = MarketHelper.fromBigint(stats.low_price);
        stats.volume = MarketHelper.fromBigint(stats.volume);
      }
      return tradeStats;
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
            error: this.formatError("" + err)
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
        error: this.formatError(message)
      });
    },
    formatError: function(message) {
      message = message.replace("Error: ER_DUP_ENTRY: ", "");
      message = message.replace(/for key.*$/, "");
      message = message.replace(/Duplicate entry/, "Value already taken");
      message = message.replace("ConflictError ", "");
      return _str.trim(message);
    }
  };

  exports = module.exports = JsonRenderer;

}).call(this);
