(function() {
  var JsonRenderer, MarketStats, OrderLog, TradeStats;

  MarketStats = GLOBAL.db.MarketStats;

  TradeStats = GLOBAL.db.TradeStats;

  OrderLog = GLOBAL.db.OrderLog;

  JsonRenderer = require("./../lib/json_renderer");

  module.exports = function(app) {
    app.get("/v1/market/summary", function(req, res, next) {
      return MarketStats.findEnabledMarkets(null, null, function(err, marketStats) {
        return res.send(JsonRenderer.marketSummary(marketStats));
      });
    });
    app.get("/v1/market/summary/:exchange", function(req, res, next) {
      return MarketStats.findEnabledMarkets(null, req.params.exchange).complete(function(err, marketStats) {
        return res.send(JsonRenderer.marketSummary(marketStats));
      });
    });
    app.get("/v1/market/stats/:coin/:exchange", function(req, res, next) {
      return MarketStats.findEnabledMarkets(req.params.coin, req.params.exchange).complete(function(err, marketStats) {
        return res.send(JsonRenderer.marketSummary(marketStats));
      });
    });
    app.get("/v1/market/trades/:coin/:exchange", function(req, res, next) {
      var options;
      options = {};
      options.currency1 = req.params.coin;
      options.currency2 = req.params.exchange;
      return OrderLog.findActiveByOptions(options, function(err, lastTrades) {
        return res.send(lastTrades);
      });

      /*res.send [{
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
       */
    });
    app.get("/v1/market/orders/:coin/:exchange/:type", function(req, res, next) {
      return res.send([
        {
          "count": "23",
          "type": "BUY",
          "orders": [
            {
              "price": "0.00000023",
              "amount": "22446985.14519785",
              "total": "5.16280655"
            }
          ]
        }
      ]);
    });
    return app.get("/v1/market/chartdata/:market_id/:period?", function(req, res, next) {
      return res.send([
        {
          "date": "2014-02-09 14:20",
          "open": "0.00000006",
          "close": "0.00000006",
          "high": "0.00000006",
          "low": "0.00000003",
          "exchange_volume": "0.00002145",
          "coin_volume": "608.50000000"
        }, {
          "date": "2014-02-09 14:20",
          "open": "0.00000006",
          "close": "0.00000006",
          "high": "0.00000006",
          "low": "0.00000003",
          "exchange_volume": "0.00002145",
          "coin_volume": "608.50000000"
        }
      ]);
    });
  };

}).call(this);
