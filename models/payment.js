(function() {
  var MarketHelper, ipFormatter;

  MarketHelper = require("../lib/market_helper");

  ipFormatter = require("ip");

  module.exports = function(sequelize, DataTypes) {
    var Payment;
    Payment = sequelize.define("Payment", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      wallet_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      transaction_id: {
        type: DataTypes.STRING(64),
        allowNull: true
      },
      currency: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        get: function() {
          return MarketHelper.getCurrencyLiteral(this.getDataValue("currency"));
        },
        set: function(currency) {
          return this.setDataValue("currency", MarketHelper.getCurrency(currency));
        }
      },
      address: {
        type: DataTypes.STRING(34),
        allowNull: false,
        validate: {
          isValidAddress: function(value) {
            var pattern;
            pattern = /^[1-9A-Za-z]{27,34}/;
            if (!pattern.test(value)) {
              throw new Error("Invalid address.");
            }
          }
        }
      },
      amount: {
        type: DataTypes.FLOAT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        validate: {
          isFloat: true,
          notNull: true,
          min: 0.00000001
        }
      },
      status: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: MarketHelper.getPaymentStatus("pending"),
        comment: "pending, processed, canceled",
        get: function() {
          return MarketHelper.getPaymentStatusLiteral(this.getDataValue("status"));
        },
        set: function(status) {
          return this.setDataValue("status", MarketHelper.getPaymentStatus(status));
        }
      },
      log: {
        type: DataTypes.TEXT,
        set: function(response) {
          var e;
          if (!this.log) {
            this.log = "";
          }
          if (this.log.length) {
            this.log += ",";
          }
          try {
            return this.log += JSON.stringify(response);
          } catch (_error) {
            e = _error;
          }
        }
      },
      remote_ip: {
        type: DataTypes.INTEGER,
        allowNull: true,
        set: function(ip) {
          return this.setDataValue("remote_ip", ipFormatter.toLong(ip));
        },
        get: function() {
          return ipFormatter.fromLong(this.getDataValue("remote_ip"));
        }
      }
    }, {
      tableName: "payments",
      classMethods: {
        findById: function(id, callback) {
          return Payment.find(id).complete(callback);
        },
        findByUserAndWallet: function(userId, walletId, status, callback) {
          var query;
          query = {
            where: {
              user_id: userId,
              wallet_id: walletId,
              status: MarketHelper.getPaymentStatus(status)
            }
          };
          return Payment.findAll(query).complete(callback);
        },
        findByStatus: function(status, callback) {
          var query;
          query = {
            where: {
              status: MarketHelper.getPaymentStatus(status)
            },
            order: [["created_at", "ASC"]]
          };
          return Payment.findAll(query).complete(callback);
        },
        findByTransaction: function(transactionId, callback) {
          var query;
          query = {
            where: {
              transaction_id: transactionId
            }
          };
          return Payment.find(query).complete(callback);
        }
      },
      instanceMethods: {
        isProcessed: function() {
          return this.status === "processed";
        },
        isCanceled: function() {
          return this.status === "canceled";
        },
        isPending: function() {
          return this.status === "pending";
        },
        process: function(response, callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.status = "processed";
          this.transaction_id = response;
          this.log = response;
          return this.save().complete(callback);
        },
        cancel: function(reason, callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.status = "canceled";
          this.log = reason;
          return this.save().complete(function(e, p) {
            return callback(reason, p);
          });
        },
        errored: function(reason, callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.log = reason;
          return this.save().complete(function(e, p) {
            return callback(reason, p);
          });
        }
      }
    });
    return Payment;
  };

}).call(this);
