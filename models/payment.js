(function() {
  var Payment, PaymentSchema, exports;

  PaymentSchema = new Schema({
    user_id: {
      type: String,
      index: true
    },
    wallet_id: {
      type: String,
      index: true
    },
    address: {
      type: String
    },
    amount: {
      type: Number,
      "default": 0
    },
    status: {
      type: String,
      "enum": ["pending", "processed", "canceled"],
      "default": "pending"
    },
    log: {
      type: [String],
      "default": []
    },
    remote_ip: {
      type: String
    },
    updated: {
      type: Date,
      "default": Date.now
    },
    created: {
      type: Date,
      "default": Date.now,
      index: true
    }
  });

  PaymentSchema.methods.isProcessed = function() {
    return this.status === "processed";
  };

  PaymentSchema.methods.isCanceled = function() {
    return this.status === "canceled";
  };

  PaymentSchema.methods.process = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.status = "processed";
    return this.save(callback);
  };

  PaymentSchema.methods.cancel = function(reason, callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.status = "canceled";
    this.log.push(reason);
    return this.save(callback);
  };

  Payment = mongoose.model("Payment", PaymentSchema);

  exports = module.exports = Payment;

}).call(this);
