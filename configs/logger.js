(function() {
  var consoleError, consoleLog;

  consoleLog = console.log;

  consoleError = console.error;

  console.log = function() {
    var args;
    args = arguments;
    if (args[0]) {
      args[0] = "" + (new Date().toGMTString()) + " - log: " + args[0];
    }
    return consoleLog.apply(void 0, args);
  };

  console.error = function() {
    var args;
    args = arguments;
    if (args[0]) {
      args[0] = "" + (new Date().toGMTString()) + " - error: " + args[0];
    }
    return consoleError.apply(void 0, args);
  };

  process.on("uncaughtException", function(err) {
    console.error("Uncaught exception, exiting...", err.stack);
    return process.exit();
  });

}).call(this);
