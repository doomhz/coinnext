(function() {
  var TradeStats, TradeStatsSchema, exports;

  TradeStatsSchema = new Schema({
    type: {
      type: String,
      index: {
        unique: true
      }
    },
    open_price: {
      type: Number,
      "default": 0
    },
    close_price: {
      type: Number,
      "default": 0
    },
    high_price: {
      type: Number,
      "default": 0
    },
    low_price: {
      type: Number,
      "default": 0
    },
    volume: {
      type: Number,
      "default": 0
    },
    start_time: {
      type: Date,
      index: true
    },
    end_time: {
      type: Date
    }
  });

  TradeStatsSchema.set("autoIndex", false);

  TradeStatsSchema.statics.getLastStats = function(type, callback) {
    var aDayAgo, halfHour;
    if (callback == null) {
      callback = function() {};
    }
    halfHour = 1800000;
    aDayAgo = Date.now() - 86400000 - halfHour;
    return TradeStats.find({
      type: type,
      start_time: {
        $gt: aDayAgo
      }
    }).sort({
      start_time: "asc"
    }).exec(callback);
  };

  TradeStats = mongoose.model("TradeStats", TradeStatsSchema);

  exports = module.exports = TradeStats;

}).call(this);
