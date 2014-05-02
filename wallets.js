// Configure logger
if (process.env.NODE_ENV === "production") require("./configs/logger");

// Configure modules
var restify = require('restify');
var fs = require('fs');
var environment = process.env.NODE_ENV || 'development';
var config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', encoding='utf8'))[environment];

// Configure globals
GLOBAL.appConfig = function () {return config;};
GLOBAL.wallets = require('./configs/wallets');
GLOBAL.db = require('./models/index');

// Setup express
var server = restify.createServer();
server.use(restify.bodyParser());
var port = process.env.PORT || 6000;
server.listen(process.env.PORT || 6000, function(){
  console.log("Coinnext Wallets engine is running on port %d in %s mode", port, environment);
});


// Routes
require('./routes/wallets_engine/wallets')(server);
require('./routes/wallets_engine/transactions')(server);
require('./routes/wallets_engine/trade')(server);
require('./routes/wallets_engine/stats')(server);