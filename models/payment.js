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
    transaction_id: {
      type: String,
      index: true
    },
    currency: {
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

  PaymentSchema.methods.isPending = function() {
    return this.status === "pending";
  };

  PaymentSchema.methods.process = function(response, callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.status = "processed";
    this.transaction_id = response;
    this.log.push(JSON.stringify(response));
    return this.save(callback);
  };

  PaymentSchema.methods.cancel = function(reason, callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.status = "canceled";
    reason = JSON.stringify(reason);
    this.log.push(reason);
    return this.save(function(e, p) {
      return callback(reason, p);
    });
  };

  PaymentSchema.methods.errored = function(reason, callback) {
    if (callback == null) {
      callback = function() {};
    }
    reason = JSON.stringify(reason);
    this.log.push(reason);
    return this.save(function(e, p) {
      return callback(reason, p);
    });
  };

  Payment = mongoose.model("Payment", PaymentSchema);

  exports = module.exports = Payment;

}).call(this);
