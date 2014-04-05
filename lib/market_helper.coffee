_ = require "underscore"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

FEE = 0.2

#CURRENCIES = [
#  "BTC", "LTC", "PPC", "WDC", "NMC", "QRK",
#  "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"
#]

CURRENCIES =
  BTC: 1
  LTC: 2
  PPC: 3
  DOGE: 4

CURRENCY_NAMES =
  BTC: "Bitcoin"
  LTC: "Litecoin"
  PPC: "Peercoin"
  DOGE: "Dogecoin"

AVAILABLE_MARKETS =
  LTC_BTC: 1
  PPC_BTC: 2
  DOGE_BTC: 3

ORDER_TYPES =
  market: 1
  limit: 2

ORDER_ACTIONS =
  buy: 1
  sell: 2

ORDER_STATUS =
  open: 1
  partiallyCompleted: 2
  completed: 3

PAYMENT_STATUS =
  pending: 1
  processed: 2
  canceled: 3

TRANSACTION_ACCEPTED_CATEGORIES =
  send: 1
  receive: 2

TRANSACTION_MIN_CONF = 3

TOKENS =
  email_confirmation: 1
  google_auth: 2
  change_password: 3

MARKET_STATUS =
  enabled: 1
  disabled: 2

MarketHelper =

  getMarkets: ()->
    AVAILABLE_MARKETS

  getMarket: (type)->
    AVAILABLE_MARKETS[type]

  getMarketTypes: ()->
    Object.keys AVAILABLE_MARKETS

  getMarketLiteral: (intType)->
    _.invert(AVAILABLE_MARKETS)[intType]

  isValidMarket: (action, buyCurrency, sellCurrency)->
    market = "#{buyCurrency}_#{sellCurrency}"  if action is "buy"
    market = "#{sellCurrency}_#{buyCurrency}"  if action is "sell"
    !!AVAILABLE_MARKETS[market]

  getOrderStatus: (status)->
    ORDER_STATUS[status]

  getOrderStatusLiteral: (intStatus)->
    _.invert(ORDER_STATUS)[intStatus]

  getOrderAction: (action)->
    ORDER_ACTIONS[action]

  getOrderActionLiteral: (intAction)->
    _.invert(ORDER_ACTIONS)[intAction]

  getOrderType: (type)->
    ORDER_TYPES[type]

  getOrderTypeLiteral: (intType)->
    _.invert(ORDER_TYPES)[intType]

  getCurrencies: (currency)->
    CURRENCIES

  getCurrencyTypes: ()->
    Object.keys CURRENCIES

  getCurrency: (currency)->
    CURRENCIES[currency]

  getCurrencyLiteral: (intCurrency)->
    _.invert(CURRENCIES)[intCurrency]

  getCurrencyNames: ()->
    CURRENCY_NAMES

  getCurrencyName: (currency)->
    CURRENCY_NAMES[currency]

  isValidCurrency: (currency)->
    !!CURRENCIES[currency]

  getPaymentStatus: (status)->
    PAYMENT_STATUS[status]

  getPaymentStatusLiteral: (intStatus)->
    _.invert(PAYMENT_STATUS)[intStatus]

  getTransactionCategory: (category)->
    TRANSACTION_ACCEPTED_CATEGORIES[category]

  getTransactionCategoryLiteral: (intCategory)->
    _.invert(TRANSACTION_ACCEPTED_CATEGORIES)[intCategory]

  getTransactionMinConf: ()->
    TRANSACTION_MIN_CONF

  convertToBigint: (value)->
    math.multiply parseFloat(value), 100000000

  convertFromBigint: (value)->
    math.divide parseFloat(value), 100000000

  getTokenTypeLiteral: (intType)->
    _.invert(TOKENS)[intType]

  getTokenType: (type)->
    TOKENS[type]

  getMarketStatus: (status)->
    MARKET_STATUS[status]

  getMarketStatusLiteral: (intStatus)->
    _.invert(MARKET_STATUS)[intStatus]

  getTradeFee: ()->
    FEE

exports = module.exports = MarketHelper