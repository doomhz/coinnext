(function() {
  var MarketStats, MarketStatsSchema, exports;

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
    growth: {
      type: Boolean,
      "default": false
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

  MarketStatsSchema.statics.trackFromOrder = function(order) {
    var type;
    type = order.action === "buy" ? "" + order.buy_currency + "_" + order.sell_currency : "" + order.sell_currency + "_" + order.buy_currency;
    return MarketStats.findOne({
      type: type
    }, function(err, marketStats) {
      if (order.action === "buy") {
        marketStats.growth = marketStats.last_price <= order.unit_price;
        marketStats.growth_ratio = (order.unit_price - marketStats.last_price) * (marketStats.last_price / 100);
        marketStats.last_price = order.unit_price;
        if (order.unit_price > marketStats.day_high) {
          marketStats.day_high = order.unit_price;
        }
        if (order.unit_price > marketStats.day_low) {
          marketStats.day_low = order.unit_price;
        }
        marketStats.volume1 += order.amount;
        marketStats.volume2 += order.result_amount;
        return marketStats.save();
      }
    });
  };

  MarketStats = mongoose.model("MarketStats", MarketStatsSchema);

  exports = module.exports = MarketStats;

}).call(this);
