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
  GLOBAL.queue.Event.findNextValid(function (err, event) {
    if (err) return exit("Could not fetch the next event. Exitting...", err);
    if (!event) {
      setTimeout(processEvents, QUEUE_DELAY);
    } else if (event.type === "order_canceled") {
      return processCancellation(event, function (err) {
        if (err) return exit("Could not process cancellation. Exitting...", err);
        setTimeout(processEvents, QUEUE_DELAY);
      });
    } else if (event.type === "order_added") {
      return processAdd(event, function (err) {
        if (err) return exit("Could not process order add. Exitting...", err);
        setTimeout(processEvents, QUEUE_DELAY);
      });
    } else if (event.type === "orders_match") {
      return processMatch(event, function (err) {
        if (err) return exit("Could not process order match. Exitting...", err);
        setTimeout(processEvents, QUEUE_DELAY);
      });
    }
  });
};

var processCancellation = function (event, callback) {
  TradeHelper.cancelOrder(event.loadout.order_id, function (err) {
    if (!err) {
      event.status = "processed";
      event.save().complete(function () {
        return callback();
      });
    } else {
      console.error("Could not process event " + event.id, err);
      return callback();
    }
  });
};

var processAdd = function (event, callback) {
  TradeHelper.publishOrder(event.loadout.order_id, function (err) {
    if (!err) {
      event.status = "processed";
      event.save().complete(function () {
        return callback();
      });
    } else {
      console.error("Could not process event " + event.id, err);
      return callback();
    }
  });
};

var processMatch = function (event, callback) {
  TradeHelper.matchOrders(event.loadout, function (err) {
    if (!err) {
      event.status = "processed";
      event.save().complete(function () {
        return callback();
      });
    } else {
      console.error("Could not process event " + event.id, err);
      return callback();
    }
  });
};

var exit = function (errMessage, err) {
  console.error(errMessage, err);
  process.exit();
};

processEvents();


console.log("processing events...");