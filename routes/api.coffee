MarketStats = GLOBAL.db.MarketStats
TradeStats = GLOBAL.db.TradeStats
OrderLog = GLOBAL.db.OrderLog
Order = GLOBAL.db.Order
JsonRenderer = require "./../lib/json_renderer"

module.exports = (app)->

  # Provides an overview of all our markets
  app.get "/v1/market/summary", (req, res, next)->
    MarketStats.findEnabledMarkets null, null, (err, marketStats)->
      res.send JsonRenderer.marketSummary marketStats
  
  # Provides an overview of only BTC markets at this time
  # Example: /v1/market/summary/BTC
  app.get "/v1/market/summary/:exchange", (req, res, next)->
    MarketStats.findEnabledMarkets(null, req.params.exchange).complete (err, marketStats)->
      res.send JsonRenderer.marketSummary marketStats
  
  # Provides the statistics for a single market.
  # Example: /v1/market/trades/AUR/BTC
  app.get "/v1/market/stats/:coin/:exchange", (req, res, next)->
    MarketStats.findEnabledMarkets(req.params.coin, req.params.exchange).complete (err, marketStats)->
      res.send JsonRenderer.marketSummary marketStats

  # Fetches the last 100 trades for a given market.
  # Example: /v1/market/trades/MINT/BTC
  app.get "/v1/market/trades/:coin/:exchange", (req, res, next)->
    options = {}
    options.currency1 = req.params.coin
    options.currency2 = req.params.exchange
    options.limit = 100
    OrderLog.findActiveByOptions options, (err, orderLogs)->
      res.send JsonRenderer.lastTrades orderLogs

  # Fetches the 50 best priced orders of a given type for a given market.
  # Example: /v1/market/orders/MINT/BTC/BUY
  app.get "/v1/market/orders/:coin/:exchange/:type", (req, res, next)->
    options = {}
    options.status = "open"
    options.action = req.params.type.toLowerCase()
    options.currency1 = req.params.coin
    options.currency2 = req.params.exchange
    options.published = true
    options.limit = 50
    Order.findByOptions options, (err, orders)->
      res.send JsonRenderer.lastOrders options.action, orders

  # Fetches the chart data for a market for a given time period. 
  # The period is an optional parameter and can be either '6hh' (6 hours), '1DD' (24 hours), '3DD' (3 days), '7DD' (1 week) or 'MAX'.
  # If no period is defined, it will default to 6 hours. 
  # The market ID can be found by checking the market summary or market stats.
  # Example: /v1/market/chartdata/5/1DD
  ###app.get "/v1/market/chartdata/:market_id/:period?", (req, res, next)->
    res.send [{
        "date":"2014-02-09 14:20",
        "open":"0.00000006",
        "close":"0.00000006",
        "high":"0.00000006",
        "low":"0.00000003",
        "exchange_volume":"0.00002145",
        "coin_volume":"608.50000000",
      },{
        "date":"2014-02-09 14:20",
        "open":"0.00000006",
        "close":"0.00000006",
        "high":"0.00000006",
        "low":"0.00000003",
        "exchange_volume":"0.00002145",
        "coin_volume":"608.50000000",
      }]###

