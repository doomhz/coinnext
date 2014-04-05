(function() {
  var AVAILABLE_MARKETS, CURRENCIES, CURRENCY_NAMES, FEE, MARKET_STATUS, MarketHelper, ORDER_ACTIONS, ORDER_STATUS, ORDER_TYPES, PAYMENT_STATUS, TOKENS, TRANSACTION_ACCEPTED_CATEGORIES, TRANSACTION_MIN_CONF, exports, math, _;

  _ = require("underscore");

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  FEE = 0.2;

  CURRENCIES = {
    BTC: 1,
    LTC: 2,
    PPC: 3,
    DOGE: 4
  };

  CURRENCY_NAMES = {
    BTC: "Bitcoin",
    LTC: "Litecoin",
    PPC: "Peercoin",
    DOGE: "Dogecoin"
  };

  AVAILABLE_MARKETS = {
    LTC_BTC: 1,
    PPC_BTC: 2,
    DOGE_BTC: 3
  };

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

  TRANSACTION_MIN_CONF = 3;

  TOKENS = {
    email_confirmation: 1,
    google_auth: 2,
    change_password: 3
  };

  MARKET_STATUS = {
    enabled: 1,
    disabled: 2
  };

  MarketHelper = {
    getMarkets: function() {
      return AVAILABLE_MARKETS;
    },
    getMarket: function(type) {
      return AVAILABLE_MARKETS[type];
    },
    getMarketTypes: function() {
      return Object.keys(AVAILABLE_MARKETS);
    },
    getMarketLiteral: function(intType) {
      return _.invert(AVAILABLE_MARKETS)[intType];
    },
    isValidMarket: function(action, buyCurrency, sellCurrency) {
      var market;
      if (action === "buy") {
        market = "" + buyCurrency + "_" + sellCurrency;
      }
      if (action === "sell") {
        market = "" + sellCurrency + "_" + buyCurrency;
      }
      return !!AVAILABLE_MARKETS[market];
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
    getOrderType: function(type) {
      return ORDER_TYPES[type];
    },
    getOrderTypeLiteral: function(intType) {
      return _.invert(ORDER_TYPES)[intType];
    },
    getCurrencies: function(currency) {
      return CURRENCIES;
    },
    getCurrencyTypes: function() {
      return Object.keys(CURRENCIES);
    },
    getCurrency: function(currency) {
      return CURRENCIES[currency];
    },
    getCurrencyLiteral: function(intCurrency) {
      return _.invert(CURRENCIES)[intCurrency];
    },
    getCurrencyNames: function() {
      return CURRENCY_NAMES;
    },
    getCurrencyName: function(currency) {
      return CURRENCY_NAMES[currency];
    },
    isValidCurrency: function(currency) {
      return !!CURRENCIES[currency];
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
    getTransactionMinConf: function() {
      return TRANSACTION_MIN_CONF;
    },
    convertToBigint: function(value) {
      return math.multiply(parseFloat(value), 100000000);
    },
    convertFromBigint: function(value) {
      return math.divide(parseFloat(value), 100000000);
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
    }
  };

  exports = module.exports = MarketHelper;

}).call(this);
