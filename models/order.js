(function() {
  var MarketHelper, math, _;

  MarketHelper = require("../lib/market_helper");

  _ = require("underscore");

  math = require("../lib/math");

  module.exports = function(sequelize, DataTypes) {
    var Order;
    Order = sequelize.define("Order", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      type: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        comment: "market, limit",
        get: function() {
          return MarketHelper.getOrderTypeLiteral(this.getDataValue("type"));
        },
        set: function(type) {
          return this.setDataValue("type", MarketHelper.getOrderType(type));
        },
        validate: {
          isLimit: function(value) {
            if (value === MarketHelper.getOrderTypeLiteral("market")) {
              throw new Error("Market orders are disabled at the moment.");
            }
          },
          existentMarket: function(value) {
            if (!MarketHelper.isValidMarket(this.action, this.buy_currency, this.sell_currency)) {
              throw new Error("Invalid market.");
            }
          }
        }
      },
      action: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        comment: "buy, sell",
        get: function() {
          return MarketHelper.getOrderActionLiteral(this.getDataValue("action"));
        },
        set: function(action) {
          return this.setDataValue("action", MarketHelper.getOrderAction(action));
        },
        validate: {
          buyOrSell: function(value) {
            if (!MarketHelper.getOrderAction(this.action)) {
              throw new Error("Please submit a valid action.");
            }
          },
          sameCurrency: function(value) {
            if (this.buy_currency === this.sell_currency) {
              throw new Error("Please submit different currencies.");
            }
          }
        }
      },
      buy_currency: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        get: function() {
          return MarketHelper.getCurrencyLiteral(this.getDataValue("buy_currency"));
        },
        set: function(buyCurrency) {
          return this.setDataValue("buy_currency", MarketHelper.getCurrency(buyCurrency));
        },
        validate: {
          existentCurrency: function(value) {
            if (!MarketHelper.isValidCurrency(this.buy_currency)) {
              throw new Error("Please submit a valid buy currency.");
            }
          }
        }
      },
      sell_currency: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false,
        get: function() {
          return MarketHelper.getCurrencyLiteral(this.getDataValue("sell_currency"));
        },
        set: function(sellCurrency) {
          return this.setDataValue("sell_currency", MarketHelper.getCurrency(sellCurrency));
        },
        validate: {
          existentCurrency: function(value) {
            if (!MarketHelper.isValidCurrency(this.sell_currency)) {
              throw new Error("Please submit a valid sell currency.");
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
          minAmount: function(value) {
            if (!Order.isValidTradeAmount(value)) {
              throw new Error("Please submit a valid amount bigger than 0.0000001.");
            }
          },
          minSpendAmount: function(value) {
            if (this.action === "buy" && !Order.isValidSpendAmount(this.amount, this.action, this.unit_price)) {
              throw new Error("Total to spend must be minimum 0.0001.");
            }
          }
        },
        comment: "FLOAT x 100000000"
      },
      matched_amount: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true
        },
        comment: "FLOAT x 100000000"
      },
      result_amount: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true,
          minReceiveAmount: function(value) {
            if (this.action === "sell" && !Order.isValidReceiveAmount(this.amount, this.action, this.unit_price)) {
              throw new Error("Total to receive must be minimum 0.0001.");
            }
          }
        },
        comment: "FLOAT x 100000000"
      },
      fee: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true,
          minFee: function(value) {
            if (!Order.isValidFee(this.amount, this.action, this.unit_price)) {
              throw new Error("Minimum fee should be at least 0.00000001.");
            }
          }
        },
        comment: "FLOAT x 100000000"
      },
      unit_price: {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        validate: {
          isInt: true,
          validPrice: function(value) {
            if (this.type === "limit" && !Order.isValidUnitPriceAmount(value)) {
              throw new Error("Please submit a valid unit price amount.");
            }
          }
        },
        comment: "FLOAT x 100000000"
      },
      status: {
        type: DataTypes.INTEGER.UNSIGNED,
        defaultValue: MarketHelper.getOrderStatus("open"),
        allowNull: false,
        comment: "open, partiallyCompleted, completed",
        get: function() {
          return MarketHelper.getOrderStatusLiteral(this.getDataValue("status"));
        },
        set: function(status) {
          return this.setDataValue("status", MarketHelper.getOrderStatus(status));
        }
      },
      in_queue: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false
      },
      published: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false
      },
      close_time: {
        type: DataTypes.DATE
      }
    }, {
      tableName: "orders",
      paranoid: true,
      getterMethods: {
        inversed_action: function() {
          if (this.action === "sell") {
            return "buy";
          }
          if (this.action === "buy") {
            return "sell";
          }
        },
        left_amount: function() {
          return parseInt(math.subtract(MarketHelper.toBignum(this.amount), MarketHelper.toBignum(this.matched_amount)));
        },
        left_hold_balance: function() {
          if (this.action === "buy") {
            return MarketHelper.multiplyBigints(this.left_amount, this.unit_price);
          }
          if (this.action === "sell") {
            return this.left_amount;
          }
        },
        total: function() {
          return MarketHelper.multiplyBigints(this.amount, this.unit_price);
        }
      },
      classMethods: {
        findById: function(id, callback) {
          return Order.find(id).complete(callback);
        },
        findByIdWithTransaction: function(id, transaction, callback) {
          return Order.find({
            where: {
              id: id
            }
          }, {
            transaction: transaction
          }).complete(callback);
        },
        findByUserAndId: function(id, userId, callback) {
          return Order.find({
            where: {
              id: id,
              user_id: userId
            }
          }).complete(callback);
        },
        findTopBid: function(buyCurrency, sellCurrency, callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            limit: 1,
            where: {
              deleted_at: null,
              action: MarketHelper.getOrderAction("buy"),
              status: [MarketHelper.getOrderStatus("open"), MarketHelper.getOrderStatus("partiallyCompleted")],
              buy_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)],
              sell_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)]
            },
            order: [["unit_price", "DESC"]]
          };
          return Order.find(query).complete(callback);
        },
        findTopAsk: function(buyCurrency, sellCurrency, callback) {
          var query;
          if (callback == null) {
            callback = function() {};
          }
          query = {
            limit: 1,
            where: {
              deleted_at: null,
              action: MarketHelper.getOrderAction("sell"),
              status: [MarketHelper.getOrderStatus("open"), MarketHelper.getOrderStatus("partiallyCompleted")],
              buy_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)],
              sell_currency: [MarketHelper.getCurrency(buyCurrency), MarketHelper.getCurrency(sellCurrency)]
            },
            order: [["unit_price", "ASC"]]
          };
          return Order.find(query).complete(callback);
        },
        findByOptions: function(options, callback) {
          var currencies, query, status, _i, _len, _ref;
          if (options == null) {
            options = {};
          }
          query = {
            where: {},
            order: [["created_at", "DESC"]]
          };
          if (!options.include_deleted) {
            query.where.deleted_at = null;
          }
          if (options.include_logs) {
            query.include = [
              {
                model: GLOBAL.db.OrderLog,
                required: false,
                attributes: ["matched_amount", "result_amount", "unit_price"],
                where: {}
              }
            ];
          }
          if (options.limit) {
            query.limit = options.limit;
          }
          if (options.status === "open") {
            query.where.status = [MarketHelper.getOrderStatus("partiallyCompleted"), MarketHelper.getOrderStatus("open")];
          } else if (options.status === "completed") {
            query.where.status = MarketHelper.getOrderStatus(options.status);
          } else if (_.isArray(options.status)) {
            query.where.status = [];
            _ref = options.status;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              status = _ref[_i];
              query.where.status.push(MarketHelper.getOrderStatus(status));
            }
          }
          if (!!MarketHelper.getOrderAction(options.action)) {
            query.where.action = MarketHelper.getOrderAction(options.action);
          }
          if (options.user_id != null) {
            query.where.user_id = options.user_id;
          }
          if (options.action === "buy") {
            if (options.currency1 != null) {
              query.where.buy_currency = MarketHelper.getCurrency(options.currency1);
            }
            if (options.currency2 != null) {
              query.where.sell_currency = MarketHelper.getCurrency(options.currency2);
            }
          } else if (options.action === "sell") {
            if (options.currency2 != null) {
              query.where.buy_currency = MarketHelper.getCurrency(options.currency2);
            }
            if (options.currency1 != null) {
              query.where.sell_currency = MarketHelper.getCurrency(options.currency1);
            }
          } else if (!options.action) {
            currencies = [];
            if (options.currency1 != null) {
              currencies.push(MarketHelper.getCurrency(options.currency1));
            }
            if (options.currency2 != null) {
              currencies.push(MarketHelper.getCurrency(options.currency2));
            }
            if (currencies.length > 1) {
              query.where.buy_currency = currencies;
              query.where.sell_currency = currencies;
            } else if (currencies.length === 1) {
              query.where = sequelize.and(query.where, sequelize.or({
                buy_currency: currencies[0]
              }, {
                sell_currency: currencies[0]
              }));
            }
          } else {
            return callback("Wrong action", []);
          }
          if (options.published != null) {
            query.where.published = !!options.published;
          }
          if (options.sort_by) {
            query.order = options.sort_by;
          }
          return Order.findAll(query).complete(callback);
        },
        isValidTradeAmount: function(amount) {
          return _.isNumber(amount) && !_.isNaN(amount) && _.isFinite(amount) && amount >= MarketHelper.getMinTradeAmount();
        },
        isValidUnitPriceAmount: function(amount) {
          return _.isNumber(amount) && !_.isNaN(amount) && _.isFinite(amount) && amount >= MarketHelper.getMinUnitPriceAmount();
        },
        isValidFee: function(amount, action, unitPrice) {
          if (MarketHelper.getTradeFee() === 0) {
            return true;
          }
          if (!_.isNumber(amount) || _.isNaN(amount) || !_.isFinite(amount)) {
            return false;
          }
          return MarketHelper.calculateFee(MarketHelper.calculateResultAmount(amount, action, unitPrice)) >= MarketHelper.getMinFeeAmount();
        },
        isValidSpendAmount: function(amount, action, unitPrice) {
          if (!_.isNumber(amount) || _.isNaN(amount) || !_.isFinite(amount)) {
            return false;
          }
          return MarketHelper.calculateSpendAmount(amount, action, unitPrice) >= MarketHelper.getMinSpendAmount();
        },
        isValidReceiveAmount: function(amount, action, unitPrice) {
          if (!_.isNumber(amount) || _.isNaN(amount) || !_.isFinite(amount)) {
            return false;
          }
          return MarketHelper.calculateResultAmount(amount, action, unitPrice) >= MarketHelper.getMinReceiveAmount();
        }
      },
      instanceMethods: {
        getFloat: function(attribute) {
          if (this[attribute] == null) {
            return this[attribute];
          }
          return MarketHelper.fromBigint(this[attribute]);
        },
        canBeCanceled: function() {
          return !this.in_queue && this.status !== "completed";
        },
        publish: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          return GLOBAL.coreAPIClient.sendWithData("publish_order", this.values, (function(_this) {
            return function(err, res, body) {
              if (err) {
                console.error(err);
                return callback(err, res, body);
              }
              if (body && body.id) {
                return Order.findById(body.id, callback);
              }
              console.error("Could not publish the order - " + (JSON.stringify(body)));
              return callback(body);
            };
          })(this));
        },
        cancel: function(callback) {
          if (callback == null) {
            callback = function() {};
          }
          return GLOBAL.coreAPIClient.send("cancel_order", [this.id], (function(_this) {
            return function(err, res, body) {
              if (err) {
                console.error(err);
                return callback(err, res, body);
              }
              if (body && body.id) {
                return callback();
              } else {
                console.error("Could not cancel the order - " + (JSON.stringify(body)));
                return callback("Could not cancel the order on the network");
              }
            };
          })(this));
        },
        updateFromMatchedData: function(matchedData, transaction, callback) {
          if (callback == null) {
            callback = function() {};
          }
          this.status = matchedData.status;
          this.matched_amount = parseInt(math.add(MarketHelper.toBignum(this.matched_amount), MarketHelper.toBignum(matchedData.matched_amount)));
          this.result_amount = parseInt(math.add(MarketHelper.toBignum(this.result_amount), MarketHelper.toBignum(matchedData.result_amount)));
          this.fee = parseInt(math.add(MarketHelper.toBignum(this.fee), MarketHelper.toBignum(matchedData.fee)));
          if (this.status === "completed") {
            this.close_time = new Date(matchedData.time);
          }
          return this.save({
            transaction: transaction
          }).complete(callback);
        },
        calculateReceivedFromLogs: function(toFloat) {
          var log, resultAmount, _i, _len, _ref;
          if (toFloat == null) {
            toFloat = false;
          }
          resultAmount = 0;
          _ref = this.orderLogs;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            log = _ref[_i];
            resultAmount = parseInt(math.add(MarketHelper.toBignum(resultAmount), MarketHelper.toBignum(log.result_amount)));
          }
          if (toFloat) {
            return MarketHelper.fromBigint(resultAmount);
          } else {
            return resultAmount;
          }
        },
        calculateSpentFromLogs: function(toFloat) {
          var log, spentAmount, _i, _j, _len, _len1, _ref, _ref1;
          if (toFloat == null) {
            toFloat = false;
          }
          spentAmount = 0;
          if (this.action === "buy") {
            _ref = this.orderLogs;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              log = _ref[_i];
              spentAmount = parseInt(math.add(MarketHelper.toBignum(spentAmount), MarketHelper.toBignum(log.total)));
            }
          } else {
            _ref1 = this.orderLogs;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              log = _ref1[_j];
              spentAmount = parseInt(math.add(MarketHelper.toBignum(spentAmount), MarketHelper.toBignum(log.matched_amount)));
            }
          }
          if (toFloat) {
            return MarketHelper.fromBigint(spentAmount);
          } else {
            return spentAmount;
          }
        }
      }
    });
    return Order;
  };

}).call(this);
