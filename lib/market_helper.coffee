marketSettings = require "./market_settings"
_ = require "underscore"
math = require "./math"

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
  removed: 3

WALLET_STATUS =
  normal: 1
  delayed: 2
  blocked: 3
  inactive: 4
  error: 5

EVENT_TYPE =
  orders_match: 1
  cancel_order: 2
  order_canceled: 3
  add_order: 4
  order_added: 5

EVENT_STATUS =
  pending: 1
  processed: 2

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

  isValidExchange: (exchange)->
    for market in @getMarketTypes()
      if market.indexOf("_#{exchange}") > -1
        return true
    return false

  isValidMarketPair: (coin, exchange)->
    market = "#{coin}_#{exchange}"
    !!marketSettings.AVAILABLE_MARKETS[market]    

  getOrderStatus: (status)->
    ORDER_STATUS[status]

  getOrderStatusLiteral: (intStatus)->
    _.invert(ORDER_STATUS)[intStatus]

  getOrderAction: (action)->
    ORDER_ACTIONS[action]

  getOrderActionLiteral: (intAction)->
    _.invert(ORDER_ACTIONS)[intAction]

  isValidOrderAction: (action)->
    !!ORDER_ACTIONS[action]

  getOrderType: (type)->
    ORDER_TYPES[type]

  getOrderTypeLiteral: (intType)->
    _.invert(ORDER_TYPES)[intType]

  getCurrencies: (currency)->
    marketSettings.CURRENCIES

  getCurrencyTypes: ()->
    Object.keys marketSettings.CURRENCIES

  getSortedCurrencyTypes: ()->
    types = _.sortBy @getCurrencyTypes(), (t)->
      t
    return types

  getCurrency: (currency)->
    marketSettings.CURRENCIES[currency]

  getCurrencyLiteral: (intCurrency)->
    _.invert(marketSettings.CURRENCIES)[intCurrency]

  getCurrencyNames: ()->
    marketSettings.CURRENCY_NAMES

  getSortedCurrencyNames: ()->
    types = @getSortedCurrencyTypes()
    names = {}
    for type in types
      names[type] = @getCurrencyName type
    names

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

  toBignum: (value)->
    math.bignumber "#{value}"
  
  toBigint: (value)->
    parseInt math.multiply(@toBignum(value), @toBignum(100000000))

  fromBigint: (value)->
    parseFloat math.divide(@toBignum(value), @toBignum(100000000))

  multiplyBigints: (value, value2)->
    parseInt math.round math.divide(math.multiply(@toBignum(value), @toBignum(value2)), @toBignum(100000000))

  getTokenTypeLiteral: (intType)->
    _.invert(TOKENS)[intType]

  getTokenType: (type)->
    TOKENS[type]

  getMarketStatus: (status)->
    MARKET_STATUS[status]

  getMarketStatusLiteral: (intStatus)->
    _.invert(MARKET_STATUS)[intStatus]

  getWalletStatus: (status)->
    WALLET_STATUS[status]

  getWalletStatusLiteral: (intStatus)->
    _.invert(WALLET_STATUS)[intStatus]

  getWalletLastUpdatedStatus: (lastUpdated)->
    t2 = (new Date()).getTime()
    t1 = lastUpdated.getTime()
    diffSeconds = (t2 - t1) / 1000
    return "normal" if diffSeconds <= 30 * 60
    return "delayed" if diffSeconds <= 60 * 60
    return "blocked" if diffSeconds > 60 * 60
    return "error"

  getTradeFee: ()->
    FEE

  getMinTradeAmount: ()->
    10

  getMinUnitPriceAmount: ()->
    1

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
    @multiplyBigints amount, unitPrice

  calculateFee: (amount)->
    parseInt math.select(@toBignum(amount)).divide(@toBignum(100)).multiply(@toBignum(@getTradeFee())).ceil().done()

  calculateSpendAmount: (amount, action, unitPrice)->
    return amount  if action is "sell"
    @multiplyBigints amount, unitPrice

  getWithdrawalFee: (currency)->
    return marketSettings.DEFAULT_WITHDRAWAL_FEE  if not marketSettings.WITHDRAWAL_FEES[currency]?
    marketSettings.WITHDRAWAL_FEES[currency]

  getEventType: (type)->
    EVENT_TYPE[type]

  getEventTypeLiteral: (intType)->
    _.invert(EVENT_TYPE)[intType]

  getEventStatus: (status)->
    EVENT_STATUS[status]

  getEventStatusLiteral: (intStatus)->
    _.invert(EVENT_STATUS)[intStatus]

exports = module.exports = MarketHelper