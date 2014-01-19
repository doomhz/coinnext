(function() {
  var Order, OrderSchema, exports;

  OrderSchema = new Schema({
    user_id: {
      type: String,
      index: true
    },
    type: {
      type: String,
      "enum": ["market", "limit"],
      index: true
    },
    action: {
      type: String,
      "enum": ["buy", "sell"],
      index: true
    },
    buy_currency: {
      type: String,
      index: true
    },
    sell_currency: {
      type: String,
      index: true
    },
    amount: {
      type: Number
    },
    fee: {
      type: Number
    },
    unit_price: {
      type: Number
    },
    status: {
      type: String,
      "enum": ["open", "partial", "closed"],
      "default": "open",
      index: true
    },
    created: {
      type: Date,
      "default": Date.now,
      index: true
    }
  });

  OrderSchema.set("autoIndex", false);

  /*
  OrderSchema.path("unit_price").validate ()->
      console.log @
      return false
    , "Invalid unit price"
  */


  OrderSchema.statics.findByOptions = function(options, callback) {
    var currencies, dbQuery;
    if (options == null) {
      options = {};
    }
    dbQuery = Order.find({
      status: options.status
    });
    if (["buy", "sell"].indexOf(options.action) > -1) {
      dbQuery.where({
        action: options.action
      });
    }
    if (options.user_id) {
      dbQuery.where({
        user_id: options.user_id
      });
    }
    if (options.action === "buy") {
      dbQuery.where({
        buy_currency: options.currency2,
        sell_currency: options.currency1
      });
    } else if (options.action === "sell") {
      dbQuery.where({
        buy_currency: options.currency1,
        sell_currency: options.currency2
      });
    } else if (!options.action) {
      currencies = [];
      if (options.currency1) {
        currencies.push(options.currency1);
      }
      if (options.currency2) {
        currencies.push(options.currency2);
      }
      if (currencies.length > 1) {
        dbQuery.where("buy_currency")["in"](currencies).where("sell_currency")["in"](currencies);
      } else {
        dbQuery.or([
          {
            buy_currency: currencies[0]
          }, {
            sell_currency: currencies[0]
          }
        ]);
      }
    } else {
      callback("Wrong action", []);
    }
    return dbQuery.exec(callback);
  };

  Order = mongoose.model("Order", OrderSchema);

  exports = module.exports = Order;

}).call(this);
