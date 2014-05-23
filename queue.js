// Configure logger
if (process.env.NODE_ENV === "production") require("./configs/logger");

// Configure modules
var environment = process.env.NODE_ENV || 'development';
var QUEUE_DELAY = 1000

// Configure globals
GLOBAL.appConfig = require("./configs/config");
GLOBAL.db = require('./models/index');
GLOBAL.queue = require('./lib/queue/index');

var TradeHelper = require('./lib/trade_helper');

var processEvents = function () {
  GLOBAL.queue.Event.findNext(function (err, event) {
    if (!event) return setTimeout(processEvents, QUEUE_DELAY);
    TradeHelper.matchOrders(event.loadout, function (err) {
      if (!err) {
        event.status = "sent";
        event.save().complete(function () {
          setTimeout(processEvents, QUEUE_DELAY);
        });
      } else {
        console.error("Could not process event " + event.id, err);
        setTimeout(processEvents, QUEUE_DELAY)
      }
    });
  });
};

processEvents();

console.log("processing events...");