(function() {
  var AVAILABLE_MARKETS, CURRENCIES, CURRENCY_NAMES, FEE, MARKET_STATUS, MarketHelper, ORDER_ACTIONS, ORDER_STATUS, ORDER_TYPES, PAYMENT_STATUS, TOKENS, TRANSACTION_ACCEPTED_CATEGORIES, WITHDRAWAL_FEES, exports, math, _;

  _ = require("underscore");

  math = require("mathjs")({
    number: "bignumber",
    decimals: 8
  });

  FEE = 0;

  CURRENCIES = {
    BTC: 1,
    LTC: 2,
    PPC: 3,
    DOGE: 4,
    NMC: 5,
    DRK: 6,
    XPM: 7,
    BC: 8,
    VTC: 9,
    METH: 10,
    NLG: 11,
    TCO: 12,
    CX: 13,
    BANK: 14,
    BRM: 15,
    GAY: 16
  };

  CURRENCY_NAMES = {
    BTC: "Bitcoin",
    LTC: "Litecoin",
    PPC: "Peercoin",
    DOGE: "Dogecoin",
    NMC: "Namecoin",
    DRK: "Darkcoin",
    XPM: "Primecoin",
    BC: "Blackcoin",
    VTC: "Vertcoin",
    METH: "Cryptometh",
    NLG: "Guldencoin",
    TCO: "Tacocoin",
    CX: "Xtracoin",
    BANK: "Bankcoin",
    BRM: "Bitraam",
    GAY: "Homocoin"
  };

  AVAILABLE_MARKETS = {
    LTC_BTC: 1,
    PPC_BTC: 2,
    DOGE_BTC: 3,
    NMC_BTC: 4,
    DRK_BTC: 5,
    XPM_BTC: 6,
    BC_BTC: 7,
    VTC_BTC: 8,
    METH_BTC: 9,
    NLG_BTC: 10,
    TCO_BTC: 11,
    CX_BTC: 12,
    BANK_BTC: 13,
    BRM_BTC: 14,
    GAY_BTC: 15
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

  WITHDRAWAL_FEES = {
    BTC: 20000,
    LTC: 200000,
    PPC: 2000000,
    DOGE: 200000000,
    NMC: 200000,
    DRK: 200000,
    XPM: 200000,
    BC: 200000,
    VTC: 200000,
    METH: 200000,
    NLG: 200000,
    TCO: 200000,
    CX: 200000,
    BANK: 200000,
    BRM: 200000,
    GAY: 200000
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
    getExchangeMarketsId: function(exchange) {
      var id, marketType, marketsId;
      marketsId = [];
      for (marketType in AVAILABLE_MARKETS) {
        id = AVAILABLE_MARKETS[marketType];
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
      return WITHDRAWAL_FEES[currency];
    }
  };

  exports = module.exports = MarketHelper;

}).call(this);
