// Configure logger
if (process.env.NODE_ENV === "production") require("./configs/logger");

// Configure modules
var restify = require('restify');
var environment = process.env.NODE_ENV || 'development';

// Configure globals
GLOBAL.appConfig = require("./configs/config");
GLOBAL.wallets = require('./configs/wallets');
GLOBAL.db = require('./models/index');
GLOBAL.queue = require('./lib/queue/index');

// Setup express
var server = restify.createServer();
server.use(restify.bodyParser());
var port = process.env.PORT || 6000;
server.listen(process.env.PORT || 6000, function(){
  console.log("Coinnext Core API is running on port %d in %s mode", port, environment);
});


// Routes
require('./routes/core_api/wallets')(server);
require('./routes/core_api/transactions')(server);
require('./routes/core_api/trade')(server);
require('./routes/core_api/stats')(server);