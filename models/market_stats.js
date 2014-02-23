(function() {
  var MARKETS, MarketStats, MarketStatsSchema, exports;

  MARKETS = ["LTC_BTC", "PPC_BTC"];

  MarketStatsSchema = new Schema({
    type: {
      type: String,
      index: {
        unique: true
      }
    },
    label: {
      type: String
    },
    last_price: {
      type: Number,
      "default": 0
    },
    day_high: {
      type: Number,
      "default": 0
    },
    day_low: {
      type: Number,
      "default": 0
    },
    volume1: {
      type: Number,
      "default": 0
    },
    volume2: {
      type: Number,
      "default": 0
    },
    growth_ratio: {
      type: Number,
      "default": 0
    }
  });

  MarketStatsSchema.set("autoIndex", false);

  MarketStatsSchema.statics.getStats = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    return MarketStats.find({}, function(err, marketStats) {
      var stat, stats, _i, _len;
      stats = {};
      for (_i = 0, _len = marketStats.length; _i < _len; _i++) {
        stat = marketStats[_i];
        stats[stat.type] = stat;
      }
      return callback(err, stats);
    });
  };

  MarketStatsSchema.statics.trackFromOrder = function(order, callback) {
    var type;
    if (callback == null) {
      callback = function() {};
    }
    type = order.action === "buy" ? "" + order.buy_currency + "_" + order.sell_currency : "" + order.sell_currency + "_" + order.buy_currency;
    if (order.action === "sell") {
      return MarketStats.findOne({
        type: type
      }, function(err, marketStats) {
        if (order.unit_price !== marketStats.last_price) {
          marketStats.growth_ratio = MarketStats.calculateGrowthRatio(marketStats.last_price, order.unit_price);
        }
        marketStats.last_price = order.unit_price;
        if (order.unit_price > marketStats.day_high) {
          marketStats.day_high = order.unit_price;
        }
        if (order.unit_price < marketStats.day_low) {
          marketStats.day_low = order.unit_price;
        }
        marketStats.volume1 += order.amount;
        marketStats.volume2 += order.result_amount;
        return marketStats.save(callback);
      });
    }
  };

  MarketStatsSchema.statics.getMarkets = function() {
    return MARKETS;
  };

  MarketStatsSchema.statics.isValidMarket = function(action, buyCurrency, sellCurrency) {
    var market;
    if (action === "buy") {
      market = "" + buyCurrency + "_" + sellCurrency;
    }
    if (action === "sell") {
      market = "" + sellCurrency + "_" + buyCurrency;
    }
    return MarketStats.getMarkets().indexOf(market) > -1;
  };

  MarketStatsSchema.statics.calculateGrowthRatio = function(lastPrice, newPrice) {
    return parseFloat(newPrice * 100 / lastPrice - 100);
  };

  MarketStats = mongoose.model("MarketStats", MarketStatsSchema);

  exports = module.exports = MarketStats;

}).call(this);
