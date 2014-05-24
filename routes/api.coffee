MarketHelper = require "../lib/market_helper"
MarketStats = GLOBAL.db.MarketStats
TradeStats = GLOBAL.db.TradeStats
OrderLog = GLOBAL.db.OrderLog
Order = GLOBAL.db.Order
JsonRenderer = require "./../lib/json_renderer"

module.exports = (app)->

  # Provides an overview of all our markets
  app.get "/v1/market/summary", (req, res, next)->
    MarketStats.findMarkets null, null, (err, marketStats)->
      return res.json({error: {code: 404, message: "Not found"}})  if err
      res.send JsonRenderer.marketSummary marketStats
  
  # Provides an overview of only BTC markets at this time
  # Example: /v1/market/summary/BTC
  app.get "/v1/market/summary/:exchange", (req, res, next)->
    exchange = req.params.exchange
    if not MarketHelper.isValidExchange(exchange)
      return res.json({error: {code: 404, message: "Not found"}})
    MarketStats.findMarkets(null, exchange).complete (err, marketStats)->
      return res.json({error: {code: 404, message: "Not found"}})  if err
      res.send JsonRenderer.marketSummary marketStats
  
  # Provides the statistics for a single market.
  # Example: /v1/market/trades/AUR/BTC
  app.get "/v1/market/stats/:coin/:exchange", (req, res, next)->
    coin = req.params.coin
    exchange = req.params.exchange
    if not MarketHelper.isValidMarketPair(coin, exchange)
      return res.json({error: {code: 404, message: "Not found"}})
    MarketStats.findMarkets(coin, exchange).complete (err, marketStats)->
      return res.json({error: {code: 404, message: "Not found"}})  if err
      res.send JsonRenderer.marketSummary marketStats

  # Fetches the last 100 trades for a given market.
  # Example: /v1/market/trades/MINT/BTC
  app.get "/v1/market/trades/:coin/:exchange", (req, res, next)->
    coin = req.params.coin
    exchange = req.params.exchange
    if not MarketHelper.isValidMarketPair(coin, exchange)
      return res.json({error: {code: 404, message: "Not found"}})
    options = {}
    options.currency1 = coin
    options.currency2 = exchange
    options.limit = 100
    OrderLog.findActiveByOptions options, (err, orderLogs)->
      return res.json({error: {code: 404, message: "Not found"}})  if err
      res.send JsonRenderer.lastTrades orderLogs

  # Fetches the 50 best priced orders of a given type for a given market.
  # Example: /v1/market/orders/MINT/BTC/BUY
  app.get "/v1/market/orders/:coin/:exchange/:type", (req, res, next)->
    coin = req.params.coin
    exchange = req.params.exchange
    type = req.params.type.toLowerCase()
    if not MarketHelper.isValidMarketPair(coin, exchange) or not MarketHelper.isValidOrderAction(type)
      return res.json({error: {code: 404, message: "Not found"}})
    options = {}
    options.status = "open"
    options.action = type
    options.currency1 = coin
    options.currency2 = exchange
    options.published = true
    options.limit = 50
    if options.action is "buy"
      options.sort_by = [
        ["unit_price", "DESC"],
        ["created_at", "ASC"]
      ]
    else if options.action is "sell"
      options.sort_by = [
        ["unit_price", "ASC"],
        ["created_at", "ASC"]
      ]
    Order.findByOptions options, (err, orders)->
      return res.json({error: {code: 404, message: "Not found"}})  if err
      res.send JsonRenderer.lastOrders options.action, orders

  # Fetches the chart data for a market for a given time period. 
  # The period is an optional parameter and can be either '6hh' (6 hours), '1DD' (24 hours), '3DD' (3 days), '7DD' (1 week) or 'MAX'.
  # If no period is defined, it will default to 6 hours. 
  # The market ID can be found by checking the market summary or market stats.
  # Example: /v1/market/chartdata/5/1DD
  app.get "/v1/market/chartdata/:market_id/:period?", (req, res, next)->
    options = {}
    options.marketId = req.params.market_id
    options.period = req.params.period if req.params.period?
    TradeStats.findByOptions options, (err, tradeStats)->
      return res.json({error: {code: 404, message: "Not found"}})  if err
      res.send JsonRenderer.chartData tradeStats
