// Configure logger
if (process.env.NODE_ENV === "production") require("./configs/logger");

// Configure modules
var environment = process.env.NODE_ENV || 'development';
var QUEUE_DELAY = 500;

// Configure globals
GLOBAL.appConfig = require("./configs/config");
GLOBAL.db = require('./models/index');
GLOBAL.queue = require('./lib/queue/index');

var TradeHelper = require('./lib/trade_helper');

var processEvents = function () {
  processNextCancellation(function () {
    processNextAdd(function () {
      processNextMatch(function () {
        setTimeout(processEvents, QUEUE_DELAY);
      });
    });
  });
};

var processNextCancellation = function (callback) {
  GLOBAL.queue.Event.findNext("order_canceled", function (err, event) {
    if (!event) return callback();
    TradeHelper.cancelOrder(event.loadout.order_id, function () {
      if (!err) {
        event.status = "sent";
        event.save().complete(function () {
          return callback();
        });
      } else {
        console.error("Could not process event " + event.id, err);
        return callback();
      }
    });
  });
};

var processNextAdd = function (callback) {
  GLOBAL.queue.Event.findNext("order_added", function (err, event) {
    if (!event) return callback();
    TradeHelper.publishOrder(event.loadout.order_id, function () {
      if (!err) {
        event.status = "sent";
        event.save().complete(function () {
          return callback();
        });
      } else {
        console.error("Could not process event " + event.id, err);
        return callback();
      }
    });
  });
};

var processNextMatch = function (callback) {
  GLOBAL.queue.Event.findNext("orders_match", function (err, event) {
    if (!event) return callback();
    TradeHelper.matchOrders(event.loadout, function (err) {
      if (!err) {
        event.status = "sent";
        event.save().complete(function () {
          return callback();
        });
      } else {
        console.error("Could not process event " + event.id, err);
        return callback();
      }
    });
  });
};

processEvents();


console.log("processing events...");