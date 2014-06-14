(function() {
  var EVENT_STATUS, EVENT_TYPE, FEE, MARKET_STATUS, MarketHelper, ORDER_ACTIONS, ORDER_STATUS, ORDER_TYPES, PAYMENT_STATUS, TOKENS, TRANSACTION_ACCEPTED_CATEGORIES, WALLET_STATUS, exports, marketSettings, math, _;

  marketSettings = require("./market_settings");

  _ = require("underscore");

  math = require("./math");

  FEE = 0;

  ORDER_TYPES = {
    market: 1,
    limit: 2
  };

  ORDER_ACTIONS = {
    buy: 1,
    sell: 2
  };

  ORDER_STATUS = {
    open: 1,
    partiallyCompleted: 2,
    completed: 3
  };

  PAYMENT_STATUS = {
    pending: 1,
    processed: 2,
    canceled: 3
  };

  TRANSACTION_ACCEPTED_CATEGORIES = {
    send: 1,
    receive: 2
  };

  TOKENS = {
    email_confirmation: 1,
    google_auth: 2,
    change_password: 3
  };

  MARKET_STATUS = {
    enabled: 1,
    disabled: 2,
    removed: 3
  };

  WALLET_STATUS = {
    normal: 1,
    delayed: 2,
    blocked: 3,
    inactive: 4,
    error: 5
  };

  EVENT_TYPE = {
    orders_match: 1,
    cancel_order: 2,
    order_canceled: 3,
    add_order: 4,
    order_added: 5
  };

  EVENT_STATUS = {
    pending: 1,
    processed: 2
  };

  MarketHelper = {
    getMarkets: function() {
      return marketSettings.AVAILABLE_MARKETS;
    },
    getMarket: function(type) {
      return marketSettings.AVAILABLE_MARKETS[type];
    },
    getMarketTypes: function() {
      return Object.keys(marketSettings.AVAILABLE_MARKETS);
    },
    getMarketLiteral: function(intType) {
      return _.invert(marketSettings.AVAILABLE_MARKETS)[intType];
    },
    getExchangeMarketsId: function(exchange) {
      var id, marketType, marketsId, _ref;
      marketsId = [];
      _ref = marketSettings.AVAILABLE_MARKETS;
      for (marketType in _ref) {
        id = _ref[marketType];
        if (marketType.indexOf("_" + exchange) > -1) {
          marketsId.push(id);
        }
      }
      return marketsId;
    },
    isValidMarket: function(action, buyCurrency, sellCurrency) {
      var market;
      if (action === "buy") {
        market = "" + buyCurrency + "_" + sellCurrency;
      }
      if (action === "sell") {
        market = "" + sellCurrency + "_" + buyCurrency;
      }
      return !!marketSettings.AVAILABLE_MARKETS[market];
    },
    isValidExchange: function(exchange) {
      var market, _i, _len, _ref;
      _ref = this.getMarketTypes();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        market = _ref[_i];
        if (market.indexOf("_" + exchange) > -1) {
          return true;
        }
      }
      return false;
    },
    isValidMarketPair: function(coin, exchange) {
      var market;
      market = "" + coin + "_" + exchange;
      return !!marketSettings.AVAILABLE_MARKETS[market];
    },
    getOrderStatus: function(status) {
      return ORDER_STATUS[status];
    },
    getOrderStatusLiteral: function(intStatus) {
      return _.invert(ORDER_STATUS)[intStatus];
    },
    getOrderAction: function(action) {
      return ORDER_ACTIONS[action];
    },
    getOrderActionLiteral: function(intAction) {
      return _.invert(ORDER_ACTIONS)[intAction];
    },
    isValidOrderAction: function(action) {
      return !!ORDER_ACTIONS[action];
    },
    getOrderType: function(type) {
      return ORDER_TYPES[type];
    },
    getOrderTypeLiteral: function(intType) {
      return _.invert(ORDER_TYPES)[intType];
    },
    getCurrencies: function(currency) {
      return marketSettings.CURRENCIES;
    },
    getCurrencyTypes: function() {
      return Object.keys(marketSettings.CURRENCIES);
    },
    getSortedCurrencyTypes: function() {
      var types;
      types = _.sortBy(this.getCurrencyTypes(), function(t) {
        return t;
      });
      return types;
    },
    getCurrency: function(currency) {
      return marketSettings.CURRENCIES[currency];
    },
    getCurrencyLiteral: function(intCurrency) {
      return _.invert(marketSettings.CURRENCIES)[intCurrency];
    },
    getCurrencyNames: function() {
      return marketSettings.CURRENCY_NAMES;
    },
    getSortedCurrencyNames: function() {
      var names, type, types, _i, _len;
      types = this.getSortedCurrencyTypes();
      names = {};
      for (_i = 0, _len = types.length; _i < _len; _i++) {
        type = types[_i];
        names[type] = this.getCurrencyName(type);
      }
      return names;
    },
    getCurrencyName: function(currency) {
      return marketSettings.CURRENCY_NAMES[currency];
    },
    isValidCurrency: function(currency) {
      return !!marketSettings.CURRENCIES[currency];
    },
    getPaymentStatus: function(status) {
      return PAYMENT_STATUS[status];
    },
    getPaymentStatusLiteral: function(intStatus) {
      return _.invert(PAYMENT_STATUS)[intStatus];
    },
    getTransactionCategory: function(category) {
      return TRANSACTION_ACCEPTED_CATEGORIES[category];
    },
    getTransactionCategoryLiteral: function(intCategory) {
      return _.invert(TRANSACTION_ACCEPTED_CATEGORIES)[intCategory];
    },
    toBignum: function(value) {
      return math.bignumber("" + value);
    },
    toBigint: function(value) {
      return parseInt(math.multiply(this.toBignum(value), this.toBignum(100000000)));
    },
    fromBigint: function(value) {
      return parseFloat(math.divide(this.toBignum(value), this.toBignum(100000000)));
    },
    multiplyBigints: function(value, value2) {
      return parseInt(math.round(math.divide(math.multiply(this.toBignum(value), this.toBignum(value2)), this.toBignum(100000000))));
    },
    getTokenTypeLiteral: function(intType) {
      return _.invert(TOKENS)[intType];
    },
    getTokenType: function(type) {
      return TOKENS[type];
    },
    getMarketStatus: function(status) {
      return MARKET_STATUS[status];
    },
    getMarketStatusLiteral: function(intStatus) {
      return _.invert(MARKET_STATUS)[intStatus];
    },
    getWalletStatus: function(status) {
      return WALLET_STATUS[status];
    },
    getWalletStatusLiteral: function(intStatus) {
      return _.invert(WALLET_STATUS)[intStatus];
    },
    getWalletLastUpdatedStatus: function(lastUpdated) {
      var diffSeconds, t1, t2;
      t2 = (new Date()).getTime();
      t1 = lastUpdated.getTime();
      diffSeconds = (t2 - t1) / 1000;
      if (diffSeconds <= 30 * 60) {
        return "normal";
      }
      if (diffSeconds <= 60 * 60) {
        return "delayed";
      }
      if (diffSeconds > 60 * 60) {
        return "blocked";
      }
      return "error";
    },
    getTradeFee: function() {
      return FEE;
    },
    getMinTradeAmount: function() {
      return 10;
    },
    getMinUnitPriceAmount: function() {
      return 1;
    },
    getMinSpendAmount: function() {
      return 10000;
    },
    getMinReceiveAmount: function() {
      return 10000;
    },
    getMinFeeAmount: function() {
      return 1;
    },
    getMinConfirmations: function(currency) {
      if (currency === "BTC") {
        return 3;
      }
      return 6;
    },
    calculateResultAmount: function(amount, action, unitPrice) {
      if (action === "buy") {
        return amount;
      }
      return this.multiplyBigints(amount, unitPrice);
    },
    calculateFee: function(amount) {
      return parseInt(math.select(this.toBignum(amount)).divide(this.toBignum(100)).multiply(this.toBignum(this.getTradeFee())).ceil().done());
    },
    calculateSpendAmount: function(amount, action, unitPrice) {
      if (action === "sell") {
        return amount;
      }
      return this.multiplyBigints(amount, unitPrice);
    },
    getWithdrawalFee: function(currency) {
      if (marketSettings.WITHDRAWAL_FEES[currency] == null) {
        return marketSettings.DEFAULT_WITHDRAWAL_FEE;
      }
      return marketSettings.WITHDRAWAL_FEES[currency];
    },
    getEventType: function(type) {
      return EVENT_TYPE[type];
    },
    getEventTypeLiteral: function(intType) {
      return _.invert(EVENT_TYPE)[intType];
    },
    getEventStatus: function(status) {
      return EVENT_STATUS[status];
    },
    getEventStatusLiteral: function(intStatus) {
      return _.invert(EVENT_STATUS)[intStatus];
    }
  };

  exports = module.exports = MarketHelper;

}).call(this);
