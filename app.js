
/**
 * Module dependencies.
 */

var express = require('express');
var http = require('http');
var RedisStore = require('connect-redis')(express);
var connectDomain = require('connect-domain');
var gzippo = require('gzippo');
var fs = require('fs');
var helmet = require('helmet');
var WalletsClient = require('./lib/wallets_client');
var environment = process.env.NODE_ENV || 'development';
var config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', encoding='utf8'))[environment];

// Configure globals
GLOBAL.passport = require('passport');
GLOBAL.appConfig = function () {return config;};
GLOBAL.walletsClient = new WalletsClient({host: GLOBAL.appConfig().wallets_host});

require('./models/db_connect_mongo');
require('./lib/auth');

// Setup the middlewares
var oneYear = 31557600000;
var gzippoOptions = environment === 'production' ? {clientMaxAge: oneYear, maxAge: oneYear} : {contentTypeMatch: /none/};
var connectAssetsOptions = environment === 'production' ? {minifyBuilds: true} : {};
var staticRenderer = environment === 'production' ? gzippo.staticGzip(__dirname + '/public', gzippoOptions) : express.static(__dirname + '/public');

// Setup express
var app = express();
if (environment === "production") {
  app.use(connectDomain());
}
connectAssetsOptions.helperContext = app.locals
app.enable("trust proxy");
app.configure(function () {
  app.set('port', process.env.PORT || 5000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser());
  app.use(express.session({
    secret: 'coinnextsecret83',
    store: new RedisStore(GLOBAL.appConfig().redis),
    cookie: {
      maxAge: 2592000000,
      path: '/'
    }
  }));
  app.use(passport.initialize());
  app.use(passport.session());
  app.use(helmet.xframe('sameorigin'));
  app.use(app.router);
  app.use(staticRenderer);
  app.use(require('connect-assets')(connectAssetsOptions));
  app.use(function(err, req, res, next) {
    console.error(err);
    res.send(500, "Oups, seems that there is an error on our side. Your coins are safe and we'll be back shortly...");
  });
});


// Configuration

app.configure('development', function(){
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

app.configure('production', function(){
  app.use(express.errorHandler());
});

var server = http.createServer(app);

GLOBAL.sockets = require("./lib/sockets")(server, environment);

server.listen(app.get('port'), function(){
  console.log("Coinnext is running on port %d in %s mode", app.get("port"), app.settings.env);
});


// Routes
require('./routes/site')(app);
require('./routes/auth')(app);
require('./routes/users')(app);
require('./routes/wallets')(app);
require('./routes/payments')(app);
require('./routes/transactions')(app);
require('./routes/orders')(app);
require('./routes/chat')(app);
