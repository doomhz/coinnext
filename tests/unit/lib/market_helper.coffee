require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"
MarketHelper = require "./../../../lib/market_helper"

describe "MarketHelper", ->

  FEE = 0.2

  ###
  CURRENCIES = [
    "BTC", "LTC", "PPC", "WDC", "NMC", "QRK",
    "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"
  ]
  ###
  CURRENCIES =
    BTC: 1
    LTC: 2
    PPC: 3
    DOGE: 4
    NMC: 5

  CURRENCY_NAMES =
    BTC: "Bitcoin"
    LTC: "Litecoin"
    PPC: "Peercoin"
    DOGE: "Dogecoin"
    NMC: "Namecoin"

  AVAILABLE_MARKETS =
    LTC_BTC: 1
    PPC_BTC: 2
    DOGE_BTC: 3
    NMC_BTC: 4

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

  WITHDRAWAL_FEES =
    BTC: 20000
    LTC: 200000
    PPC: 2000000
    DOGE: 200000000
    NMC: 200000

  TOKENS =
    email_confirmation: 1
    google_auth: 2
    change_password: 3

  MARKET_STATUS =
    enabled: 1
    disabled: 2


  describe "getMarkets", ()->
    it "returns the available markets list", ()->
      JSON.stringify(MarketHelper.getMarkets()).should.equal JSON.stringify(AVAILABLE_MARKETS)

  describe "getMarket", ()->
    it "returns the market id based on its type", ()->
      for market, marketId of AVAILABLE_MARKETS
        MarketHelper.getMarket(market).should.equal marketId
  
  describe "getMarketTypes", ()->
    it "returns the names of the available markets", ()->
      JSON.stringify(MarketHelper.getMarketTypes()).should.equal JSON.stringify(Object.keys AVAILABLE_MARKETS)

  describe "getMarketLiteral", ()->
    it "returns the market name based on its id", ()->
      for market, marketId of AVAILABLE_MARKETS
        MarketHelper.getMarketLiteral(marketId).should.equal market

  describe "isValidMarket", ()->
    it "returns true if a market for for sell given currencies exists", ()->
      for buyCurrency in ["LTC", "PPC", "DOGE"]
        for sellCurrency in ["BTC"]
          market = "#{buyCurrency}_#{sellCurrency}"
          MarketHelper.isValidMarket("buy", buyCurrency, sellCurrency).should.be.true
    it "returns true if a market for sell given currencies exists", ()->
      for buyCurrency in ["BTC"]
        for sellCurrency in ["LTC", "PPC", "DOGE"]
          market = "#{sellCurrency}_#{buyCurrency}"
          MarketHelper.isValidMarket("sell", buyCurrency, sellCurrency).should.be.true
    it "returns false for an invalid action", ()->
      MarketHelper.isValidMarket("hello", "LTC", "BTC").should.be.false
      MarketHelper.isValidMarket("hello", "BTC", "LTC").should.be.false
    it "returns false for a same currency pair", ()->
      MarketHelper.isValidMarket("buy", "BTC", "BTC").should.be.false
      MarketHelper.isValidMarket("sell", "BTC", "BTC").should.be.false

  describe "getOrderStatus", ()->
    it "returns the order status id for the given status", ()->
      for status, statusId of ORDER_STATUS
        MarketHelper.getOrderStatus(status).should.equal statusId
  
  describe "getOrderStatusLiteral", ()->
    it "returns the order status for the given status id", ()->
      for status, statusId of ORDER_STATUS
        MarketHelper.getOrderStatusLiteral(statusId).should.equal status

  describe "getOrderAction", ()->
    it "returns the order action id for the given action", ()->
      for action, actionId of ORDER_ACTIONS
        MarketHelper.getOrderAction(action).should.equal actionId
  
  describe "getOrderActionLiteral", ()->
    it "returns the order action for the given action id", ()->
      for action, actionId of ORDER_ACTIONS
        MarketHelper.getOrderActionLiteral(actionId).should.equal action

  describe "getOrderType", ()->
    it "returns the order type id for the given type", ()->
      for type, typeId of ORDER_TYPES
        MarketHelper.getOrderType(type).should.equal typeId
  
  describe "getOrderTypeLiteral", ()->
    it "returns the order type for the given type id", ()->
      for type, typeId of ORDER_TYPES
        MarketHelper.getOrderTypeLiteral(typeId).should.equal type

  describe "getCurrencies", ()->
    it "returns the available currencies list", ()->
      JSON.stringify(MarketHelper.getCurrencies()).should.equal JSON.stringify(CURRENCIES)

  describe "getCurrencyTypes", ()->
    it "returns the names of the available currencies", ()->
      JSON.stringify(MarketHelper.getCurrencyTypes()).should.equal JSON.stringify(Object.keys CURRENCIES)

  describe "getCurrency", ()->
    it "returns the currency id based on its type", ()->
      for currency, currencyId of CURRENCIES
        MarketHelper.getCurrency(currency).should.equal currencyId

  describe "getCurrencyLiteral", ()->
    it "returns the currency type for the given currency id", ()->
      for currency, currencyId of CURRENCIES
        MarketHelper.getCurrencyLiteral(currencyId).should.equal currency

  describe "getCurrencyNames", ()->
    it "returns the names of the currencies", ()->
      JSON.stringify(MarketHelper.getCurrencyNames()).should.equal JSON.stringify(CURRENCY_NAMES)

  describe "getCurrencyName", ()->
    it "returns the currency id based on its name", ()->
      for currency, currencyName of CURRENCY_NAMES
        MarketHelper.getCurrencyName(currency).should.equal currencyName
  
  describe "isValidCurrency", ()->
    it "returns true if a currency is valid", ()->
      for currency in Object.keys CURRENCIES
        MarketHelper.isValidCurrency(currency).should.be.true
    it "returns false for an invalid currency", ()->
      MarketHelper.isValidCurrency("HELLO").should.be.false

  describe "getPaymentStatus", ()->
    it "returns the payment status id for the given status", ()->
      for status, statusId of PAYMENT_STATUS
        MarketHelper.getPaymentStatus(status).should.equal statusId
  
  describe "getPaymentStatusLiteral", ()->
    it "returns the payment status for the given status id", ()->
      for status, statusId of PAYMENT_STATUS
        MarketHelper.getPaymentStatusLiteral(statusId).should.equal status

  describe "getTransactionCategory", ()->
    it "returns the id for the given category", ()->
      for category, categoryId of TRANSACTION_ACCEPTED_CATEGORIES
        MarketHelper.getTransactionCategory(category).should.equal categoryId
  
  describe "getTransactionCategoryLiteral", ()->
    it "returns the category for the given id", ()->
      for category, categoryId of TRANSACTION_ACCEPTED_CATEGORIES
        MarketHelper.getTransactionCategoryLiteral(categoryId).should.equal category

  describe "getTransactionMinConf", ()->
    it "returns the min number of confirmations required", ()->
      MarketHelper.getTransactionMinConf().should.equal TRANSACTION_MIN_CONF

  describe "toBigint", ()->
    it "converts a float to a bigint by multiplying with 10^8", ()->
      MarketHelper.toBigint(0.00000001).should.equal 1
      MarketHelper.toBigint(0.0000001).should.equal 10
      MarketHelper.toBigint(1).should.equal 100000000
  
  describe "fromBigint", ()->
    it "converts a bigint to float by dividing it with 10^8", ()->
      MarketHelper.fromBigint(0.1).should.equal 0.000000001
      MarketHelper.fromBigint(1).should.equal 0.00000001
      MarketHelper.fromBigint(10).should.equal 0.0000001
      MarketHelper.fromBigint(100000000).should.equal 1

  describe "getTokenType", ()->
    it "returns the token id for the given token", ()->
      for token, tokenId of TOKENS
        MarketHelper.getTokenType(token).should.equal tokenId
  
  describe "getTokenTypeLiteral", ()->
    it "returns the token for the given id", ()->
      for token, tokenId of TOKENS
        MarketHelper.getTokenTypeLiteral(tokenId).should.equal token

  describe "getMarketStatus", ()->
    it "returns the status id for the given market status", ()->
      for status, statusId of MARKET_STATUS
        MarketHelper.getMarketStatus(status).should.equal statusId
  
  describe "getMarketStatusLiteral", ()->
    it "returns the market status for the given id", ()->
      for status, statusId of MARKET_STATUS
        MarketHelper.getMarketStatusLiteral(statusId).should.equal status

  describe "getTradeFee", ()->
    it "returns the correct trade fee", ()->
      MarketHelper.getTradeFee().should.equal FEE

  describe "getMinTradeAmount", ()->
    it "returns the minimum trade amount", ()->
      MarketHelper.getMinTradeAmount().should.equal 10

  describe "getMinSpendAmount", ()->
    it "returns the minimum spend amount", ()->
      MarketHelper.getMinSpendAmount().should.equal 1

  describe "getMinFeeAmount", ()->
    it "returns the minimum fee amount", ()->
      MarketHelper.getMinFeeAmount().should.equal 1

  describe "calculateResultAmount", ()->
    it "returns the amount for buy", ()->
      MarketHelper.calculateResultAmount(1000, "buy", MarketHelper.toBigint(0.1)).should.equal 1000
    it "returns the amount times unitPrice for sell", ()->
      MarketHelper.calculateResultAmount(1000, "sell", MarketHelper.toBigint(0.1)).should.equal 100
  
  describe "calculateFee", ()->
    it "calculates the fee amount based on the fee in % ", ()->
      MarketHelper.calculateFee(5 * 100).should.equal FEE * 5

  describe "calculateSpendAmount", ()->
    it "returns the amount for sell", ()->
      MarketHelper.calculateSpendAmount(1000, "sell", MarketHelper.toBigint(0.1)).should.equal 1000
    it "returns the amount times unitPrice for buy", ()->
      MarketHelper.calculateSpendAmount(1000, "buy", MarketHelper.toBigint(0.1)).should.equal 100

  describe "getWithdrawalFee", ()->
    it "returns the withdrawal fee per currency", ()->
      for currency, fee of WITHDRAWAL_FEES
        MarketHelper.getWithdrawalFee(currency).should.equal fee
