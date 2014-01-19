(function() {
  var MarketStats, MarketStatsSchema, exports;

  MarketStatsSchema = new Schema({
    BTC_LTC: {
      label: {
        type: String,
        "default": "LTC"
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
    },
    BTC_PPC: {
      label: {
        type: String,
        "default": "PPC"
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
    }
  });

  MarketStatsSchema.set("autoIndex", false);

  MarketStatsSchema.statics.getStats = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    return MarketStats.findOne({}, function(err, marketStats) {
      if (!marketStats) {
        return MarketStats.create({}, function(err, marketStats) {
          return callback(err, {
            BTC_LTC: marketStats.BTC_LTC,
            BTC_PPC: marketStats.BTC_PPC
          });
        });
      } else {
        return callback(err, {
          BTC_LTC: marketStats.BTC_LTC,
          BTC_PPC: marketStats.BTC_PPC
        });
      }
    });
  };

  MarketStats = mongoose.model("MarketStats", MarketStatsSchema);

  exports = module.exports = MarketStats;

}).call(this);
