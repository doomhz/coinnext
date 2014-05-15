(function() {
  module.exports = function(app) {
    app.get("/v1/market/summary", function(req, res, next) {
      return res.send([
        {
          "market_id": "25",
          "code": "AUR",
          "exchange": "BTC",
          "last_price": "0.04600001",
          "yesterday_price": "0.04300000",
          "change": "+6.98",
          "24hhigh": "0.04980000",
          "24hlow": "0.04000050",
          "24hvol": "21.737",
          "top_bid": "0.04590000",
          "top_ask": "0.04600005"
        }, {
          "market_id": "25",
          "code": "AUR",
          "exchange": "BTC",
          "last_price": "0.04600001",
          "yesterday_price": "0.04300000",
          "change": "+6.98",
          "24hhigh": "0.04980000",
          "24hlow": "0.04000050",
          "24hvol": "21.737",
          "top_bid": "0.04590000",
          "top_ask": "0.04600005"
        }
      ]);
    });
    app.get("/v1/market/summary/:exchange", function(req, res, next) {
      return res.send([
        {
          "market_id": "25",
          "code": "AUR",
          "exchange": "BTC",
          "last_price": "0.04600001",
          "yesterday_price": "0.04300000",
          "change": "+6.98",
          "24hhigh": "0.04980000",
          "24hlow": "0.04000050",
          "24hvol": "21.737",
          "top_bid": "0.04590000",
          "top_ask": "0.04600005"
        }
      ]);
    });
    app.get("/v1/market/stats/:coin/:exchange", function(req, res, next) {
      return res.send([
        {
          "market_id": "25",
          "code": "AUR",
          "exchange": "BTC",
          "last_price": "0.04600001",
          "yesterday_price": "0.04300000",
          "change": "+6.98",
          "24hhigh": "0.04980000",
          "24hlow": "0.04000050",
          "24hvol": "21.737",
          "top_bid": "0.04590000",
          "top_ask": "0.04600005"
        }
      ]);
    });
    app.get("/v1/market/trades/:coin/:exchange", function(req, res, next) {
      return res.send([
        {
          "count": "100",
          "trades": [
            {
              "type": "1",
              "price": "0.00000023",
              "amount": "412128.80177019",
              "total": "0.09478962",
              "time": "1394498289.2727"
            }, {
              "type": "1",
              "price": "0.00000023",
              "amount": "412128.80177019",
              "total": "0.09478962",
              "time": "1394498289.2727"
            }
          ]
        }
      ]);
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
