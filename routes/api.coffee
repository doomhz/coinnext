
module.exports = (app)->

  # Provides an overview of all our markets
  app.get "/v1/market/summary", (req, res, next)->
    res.send [{
        "market_id":"25",
        "code":"AUR",
        "exchange":"BTC",
        "last_price":"0.04600001",
        "yesterday_price":"0.04300000",
        "change":"+6.98",
        "24hhigh":"0.04980000",
        "24hlow":"0.04000050",
        "24hvol":"21.737",
        "top_bid":"0.04590000",
        "top_ask":"0.04600005"
      },{
        "market_id":"25",
        "code":"AUR",
        "exchange":"BTC",
        "last_price":"0.04600001",
        "yesterday_price":"0.04300000",
        "change":"+6.98",
        "24hhigh":"0.04980000",
        "24hlow":"0.04000050",
        "24hvol":"21.737",
        "top_bid":"0.04590000",
        "top_ask":"0.04600005",
      }]
  
  # Provides an overview of only BTC markets at this time
  # Example: /v1/market/summary/BTC
  app.get "/v1/market/summary/:exchange", (req, res, next)->
    res.send [{
        "market_id":"25",
        "code":"AUR",
        "exchange":"BTC",
        "last_price":"0.04600001",
        "yesterday_price":"0.04300000",
        "change":"+6.98",
        "24hhigh":"0.04980000",
        "24hlow":"0.04000050",
        "24hvol":"21.737",
        "top_bid":"0.04590000",
        "top_ask":"0.04600005"
      }]
  
  # Provides the statistics for a single market.
  # Example: /v1/market/trades/AUR/BTC
  app.get "/v1/market/stats/:coin/:exchange", (req, res, next)->
    res.send [{
        "market_id":"25",
        "code":"AUR",
        "exchange":"BTC",
        "last_price":"0.04600001",
        "yesterday_price":"0.04300000",
        "change":"+6.98",
        "24hhigh":"0.04980000",
        "24hlow":"0.04000050",
        "24hvol":"21.737",
        "top_bid":"0.04590000",
        "top_ask":"0.04600005",
      }]

  # Fetches the last 100 trades for a given market.
  # Example: /v1/market/trades/MINT/BTC
  app.get "/v1/market/trades/:coin/:exchange", (req, res, next)->
    res.send [{
        "count":"100",
        "trades":[{
          "type":"1",
          "price":"0.00000023",
          "amount":"412128.80177019",
          "total":"0.09478962",
          "time":"1394498289.2727"
          },{
            "type":"1",
            "price":"0.00000023",
            "amount":"412128.80177019",
            "total":"0.09478962",
            "time":"1394498289.2727",  
          }
        ]
      }]

  # Fetches the 50 best priced orders of a given type for a given market.
  # Example: /v1/market/orders/MINT/BTC/BUY
  app.get "/v1/market/orders/:coin/:exchange/:type", (req, res, next)->
    res.send [{
        "count":"23",
        "type":"BUY",
        "orders":[{
          "price":"0.00000023",
          "amount":"22446985.14519785",
          "total":"5.16280655"
         },
        ]
      }]

  # Fetches the chart data for a market for a given time period. 
  # The period is an optional parameter and can be either '6hh' (6 hours), '1DD' (24 hours), '3DD' (3 days), '7DD' (1 week) or 'MAX'.
  # If no period is defined, it will default to 6 hours. 
  # The market ID can be found by checking the market summary or market stats.
  # Example: /v1/market/chartdata/5/1DD
  app.get "/v1/market/chartdata/:market_id/:period?", (req, res, next)->
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
      }]

