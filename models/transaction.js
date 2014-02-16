(function() {
  var Transaction, TransactionSchema, exports;

  TransactionSchema = new Schema({
    user_id: {
      type: String,
      index: true
    },
    wallet_id: {
      type: String,
      index: true
    },
    currency: {
      type: String,
      index: true
    },
    account: {
      type: String
    },
    fee: {
      type: String
    },
    address: {
      type: String
    },
    amount: {
      type: Number
    },
    category: {
      type: String,
      index: true
    },
    txid: {
      type: String,
      index: {
        unique: true
      }
    },
    confirmations: {
      type: Number,
      index: true
    },
    balance_loaded: {
      type: Boolean,
      "default": false
    },
    created: {
      type: Date,
      "default": Date.now,
      index: true
    }
  });

  TransactionSchema.set("autoIndex", false);

  TransactionSchema.statics.addFromWallet = function(transactionData, currency, wallet, callback) {
    var data, details, key;
    if (callback == null) {
      callback = function() {};
    }
    details = transactionData.details[0] || {};
    data = {
      user_id: (wallet ? wallet.user_id : void 0),
      wallet_id: (wallet ? wallet._id : void 0),
      currency: currency,
      account: details.account,
      fee: details.fee,
      address: details.address,
      category: details.category,
      amount: transactionData.amount,
      txid: transactionData.txid,
      confirmations: transactionData.confirmations,
      created: new Date(transactionData.time * 1000)
    };
    for (key in data) {
      if (!data[key] && data[key] !== 0) {
        delete data[key];
      }
    }
    return Transaction.findOneAndUpdate({
      txid: data.txid
    }, data, {
      upsert: true
    }, callback);
  };

  TransactionSchema.statics.findPendingByUserAndWallet = function(userId, walletId, callback) {
    return Transaction.find({
      user_id: userId,
      wallet_id: walletId
    }).where("confirmations").lt(3).sort({
      created: "desc"
    }).exec(callback);
  };

  TransactionSchema.statics.findProcessedByUserAndWallet = function(userId, walletId, callback) {
    return Transaction.find({
      user_id: userId,
      wallet_id: walletId
    }).where("confirmations").gt(2).sort({
      created: "desc"
    }).exec(callback);
  };

  TransactionSchema.statics.findPendingByIds = function(ids, callback) {
    if (ids.length === 0) {
      return callback(null, []);
    }
    return Transaction.where("txid")["in"](ids).where("confirmations").lt(3).sort({
      created: "desc"
    }).exec(callback);
  };

  TransactionSchema.statics.isValidFormat = function(category) {
    var acceptedCategories;
    acceptedCategories = ["send", "receive"];
    return acceptedCategories.indexOf(category) > -1;
  };

  Transaction = mongoose.model("Transaction", TransactionSchema);

  exports = module.exports = Transaction;

}).call(this);
