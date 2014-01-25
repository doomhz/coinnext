(function() {
  var Order, restify;

  restify = require("restify");

  Order = require("../../models/order");

  module.exports = function(app) {
    var sendToEngine;
    app.post("/publish_order/:order_id", function(req, res, next) {
      var orderId;
      orderId = req.params.order_id;
      console.log(orderId);
      return Order.findById(orderId, function(err, order) {
        var engineData, marketType, orderCurrency;
        if (err) {
          return next(new restify.ConflictError(err));
        }
        marketType = ("" + order.action + "_" + order.type).toUpperCase();
        orderCurrency = order["" + order.action + "_currency"];
        engineData = {
          eventType: "order",
          eventUserId: order.user_id,
          data: {
            orderId: orderId,
            orderType: marketType,
            orderAmount: order.amount,
            orderCurrency: orderCurrency,
            orderLimitPrice: order.unit_price
          }
        };
        return sendToEngine(engineData, function(engineError, response) {
          if (!engineError) {
            return Order.update({
              _id: orderId
            }, {
              published: true
            }, function(err, result) {
              if (!err) {
                return res.send({
                  id: orderId,
                  published: true
                });
              } else {
                return next(new restify.ConflictError(err));
              }
            });
          } else {
            return next(new restify.ConflictError("Engine error - " + engineError));
          }
        });
      });
    });
    app.put("/complete_order/:order_id/:status", function(req, res, next) {
      var orderId, status;
      orderId = req.params.order_id;
      status = req.params.status;
      return Order.findById(orderId, function(err, order) {
        return Order.update({
          _id: orderId
        }, {
          status: status
        }, function(err, result) {
          if (!err) {
            return res.send({
              id: orderId,
              status: status
            });
          } else {
            return next(new restify.ConflictError(err));
          }
        });
      });
    });
    return sendToEngine = function(data, callback) {
      var engineError, response;
      engineError = null;
      response = {};
      return callback(engineError, response);
    };
  };

}).call(this);
