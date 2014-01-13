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


  OrderSchema.statics.findOpenByUserAndWallet = function(userId, currencies, callback) {
    return Order.find({
      user_id: userId
    }).where("buy_currency")["in"](currencies).where("sell_currency")["in"](currencies).exec(callback);
  };

  Order = mongoose.model("Order", OrderSchema);

  exports = module.exports = Order;

}).call(this);
