marketSettings = require "./market_settings"
_ = require "underscore"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

FEE = 0

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

TOKENS =
  email_confirmation: 1
  google_auth: 2
  change_password: 3

MARKET_STATUS =
  enabled: 1
  disabled: 2

MarketHelper =

  getMarkets: ()->
    marketSettings.AVAILABLE_MARKETS

  getMarket: (type)->
    marketSettings.AVAILABLE_MARKETS[type]

  getMarketTypes: ()->
    Object.keys marketSettings.AVAILABLE_MARKETS

  getMarketLiteral: (intType)->
    _.invert(marketSettings.AVAILABLE_MARKETS)[intType]

  getExchangeMarketsId: (exchange)->
    marketsId = []
    for marketType, id of marketSettings.AVAILABLE_MARKETS
      marketsId.push id  if marketType.indexOf("_#{exchange}") > -1
    marketsId

  isValidMarket: (action, buyCurrency, sellCurrency)->
    market = "#{buyCurrency}_#{sellCurrency}"  if action is "buy"
    market = "#{sellCurrency}_#{buyCurrency}"  if action is "sell"
    !!marketSettings.AVAILABLE_MARKETS[market]

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
    marketSettings.CURRENCIES

  getCurrencyTypes: ()->
    Object.keys marketSettings.CURRENCIES

  getCurrency: (currency)->
    marketSettings.CURRENCIES[currency]

  getCurrencyLiteral: (intCurrency)->
    _.invert(marketSettings.CURRENCIES)[intCurrency]

  getCurrencyNames: ()->
    marketSettings.CURRENCY_NAMES

  getCurrencyName: (currency)->
    marketSettings.CURRENCY_NAMES[currency]

  isValidCurrency: (currency)->
    !!marketSettings.CURRENCIES[currency]

  getPaymentStatus: (status)->
    PAYMENT_STATUS[status]

  getPaymentStatusLiteral: (intStatus)->
    _.invert(PAYMENT_STATUS)[intStatus]

  getTransactionCategory: (category)->
    TRANSACTION_ACCEPTED_CATEGORIES[category]

  getTransactionCategoryLiteral: (intCategory)->
    _.invert(TRANSACTION_ACCEPTED_CATEGORIES)[intCategory]

  toBigint: (value)->
    math.round math.multiply(value, 100000000)

  fromBigint: (value)->
    math.divide value, 100000000

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

  getMinTradeAmount: ()->
    10

  getMinSpendAmount: ()->
    10000

  getMinReceiveAmount: ()->
    10000

  getMinFeeAmount: ()->
    1

  getMinConfirmations: (currency)->
    return 3 if currency is "BTC"
    6

  calculateResultAmount: (amount, action, unitPrice)->
    return amount  if action is "buy"
    math.multiply(amount, @fromBigint unitPrice)

  calculateFee: (amount)->
    math.select(amount).divide(100).multiply(@getTradeFee()).done()

  calculateSpendAmount: (amount, action, unitPrice)->
    return amount  if action is "sell"
    math.multiply(amount, @fromBigint unitPrice)

  getWithdrawalFee: (currency)->
    return marketSettings.DEFAULT_WITHDRAWAL_FEE  if not marketSettings.WITHDRAWAL_FEES[currency]?
    marketSettings.WITHDRAWAL_FEES[currency]

exports = module.exports = MarketHelper