(function() {
  var EVENT_STATUS, EVENT_TYPE, FEE, MARKET_STATUS, MarketHelper, ORDER_ACTIONS, ORDER_STATUS, ORDER_TYPES, PAYMENT_STATUS, TOKENS, TRANSACTION_ACCEPTED_CATEGORIES, exports, marketSettings, math, _;

  marketSettings = require("./market_settings");

  _ = require("underscore");

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

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
    disabled: 2
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
    getCurrency: function(currency) {
      return marketSettings.CURRENCIES[currency];
    },
    getCurrencyLiteral: function(intCurrency) {
      return _.invert(marketSettings.CURRENCIES)[intCurrency];
    },
    getCurrencyNames: function() {
      return marketSettings.CURRENCY_NAMES;
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
    toBigint: function(value) {
      return math.round(math.multiply(value, 100000000));
    },
    fromBigint: function(value) {
      return math.divide(value, 100000000);
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
      return math.multiply(amount, this.fromBigint(unitPrice));
    },
    calculateFee: function(amount) {
      return math.select(amount).divide(100).multiply(this.getTradeFee()).done();
    },
    calculateSpendAmount: function(amount, action, unitPrice) {
      if (action === "sell") {
        return amount;
      }
      return math.multiply(amount, this.fromBigint(unitPrice));
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
