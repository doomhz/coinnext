(function() {
  var MarketHelper, ipFormatter, math;

  MarketHelper = require("../lib/market_helper");

  ipFormatter = require("ip");

  math = require("../lib/math");

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
        allowNull: true,
        unique: true
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
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        validate: {
          isInt: true,
          notNull: true,
          isBiggerThanFee: function(value) {
            var fee;
            fee = MarketHelper.getWithdrawalFee(this.currency);
            if (value <= fee) {
              throw new Error("The amount is too low.");
            }
          }
        },
        comment: "FLOAT x 100000000"
      },
      fee: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        validate: {
          isInt: true,
          notNull: true
        },
        comment: "FLOAT x 100000000"
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
      remote_ip: {
        type: DataTypes.INTEGER,
        allowNull: true,
        set: function(ip) {
          return this.setDataValue("remote_ip", ipFormatter.toLong(ip));
        },
        get: function() {
          return ipFormatter.fromLong(this.getDataValue("remote_ip"));
        }
      },
      fraud: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
      }
    }, {
      tableName: "payments",
      classMethods: {
        findById: function(id, callback) {
          return Payment.find(id).complete(callback);
        },
        findNonProcessedById: function(id, callback) {
          return Payment.find({
            where: {
              id: id,
              status: MarketHelper.getPaymentStatus("pending")
            }
          }).complete(callback);
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
        },
        findToProcess: function(callback) {
          var query;
          query = {
            where: {
              status: MarketHelper.getPaymentStatus("pending"),
              fraud: false
            },
            order: [["created_at", "ASC"]]
          };
          return Payment.findAll(query).complete(callback);
        },
        findTotalPayedByUserAndWallet: function(userId, walletId, callback) {
          var query;
          query = {
            where: {
              user_id: userId,
              wallet_id: walletId
            }
          };
          return Payment.sum("amount", query).complete(function(err, totalAmount) {
            if (totalAmount == null) {
              totalAmount = 0;
            }
            if (err) {
              return err;
            }
            return Payment.sum("fee", query).complete(function(err, totalFee) {
              if (totalFee == null) {
                totalFee = 0;
              }
              if (err) {
                return err;
              }
              return callback(err, parseInt(math.add(MarketHelper.toBignum(totalAmount), MarketHelper.toBignum(totalFee))));
            });
          });
        },
        submit: function(data, callback) {
          if (callback == null) {
            callback = function() {};
          }
          return GLOBAL.coreAPIClient.sendWithData("create_payment", data, (function(_this) {
            return function(err, res, body) {
              if (err) {
                console.error(err);
                return callback(err, res, body);
              }
              if (body && body.id) {
                return Payment.findById(body.id, callback);
              }
              console.error("Could not create payment - " + (JSON.stringify(body)));
              return callback(body);
            };
          })(this));
        }
      },
      instanceMethods: {
        getFloat: function(attribute) {
          if (this[attribute] == null) {
            return this[attribute];
          }
          return MarketHelper.fromBigint(this[attribute]);
        },
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
          GLOBAL.db.PaymentLog.create({
            payment_id: this.id,
            log: response
          });
          return this.save().complete(callback);
        },
        cancel: function(reason, callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.status = "canceled";
          GLOBAL.db.PaymentLog.create({
            payment_id: this.id,
            log: reason
          });
          return this.save().complete(function(e, p) {
            return callback(reason, p);
          });
        },
        errored: function(reason, callback) {
          if (callback == null) {
            callback = function() {};
          }
          GLOBAL.db.PaymentLog.create({
            payment_id: this.id,
            log: reason
          });
          return this.save().complete(function(e, p) {
            return callback(reason, p);
          });
        },
        markAsFraud: function(reason, callback) {
          GLOBAL.db.PaymentLog.create({
            payment_id: this.id,
            log: JSON.stringify(reason)
          });
          this.fraud = true;
          return this.save().complete(function(e, p) {
            return callback(reason, p);
          });
        }
      }
    });
    return Payment;
  };

}).call(this);
