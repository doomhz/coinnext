// Configure logger
if (process.env.NODE_ENV === "production") require("./configs/logger");

// Configure modules
var express = require('express');
var http = require('http');
var RedisStore = require('connect-redis')(express);
var helmet = require('helmet');
var simpleCdn = require('express-simple-cdn');
var CoreAPIClient = require('./lib/core_api_client');
var environment = process.env.NODE_ENV || 'development';

// Configure globals
GLOBAL.appConfig = require("./configs/config");
GLOBAL.passport = require('passport');
GLOBAL.coreAPIClient = new CoreAPIClient({host: GLOBAL.appConfig().wallets_host});
GLOBAL.db = require('./models/index');

require('./lib/auth');

// Setup express
var app = express();
var cookieParser = express.cookieParser(GLOBAL.appConfig().session.cookie_secret);
var sessionStore = new RedisStore(GLOBAL.appConfig().redis);
var connectAssetsOptions = environment !== 'development' && environment !== 'test' ? {minifyBuilds: true, servePath: GLOBAL.appConfig().assets_host} : {};
connectAssetsOptions.helperContext = app.locals
app.locals.CDN = function(path, noKey) {
  var glueSign = path.indexOf("?") > -1 ? "&" : "?";
  var assetsKey = !noKey && GLOBAL.appConfig().assets_key ? glueSign + "_=" + GLOBAL.appConfig().assets_key : "";
  return simpleCdn(path, GLOBAL.appConfig().assets_host) + assetsKey;
};
app.enable("trust proxy");
app.disable('x-powered-by');
app.configure(function () {
  app.set('port', process.env.PORT || 5000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.compress());
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(cookieParser);
  app.use(express.session({
    key: GLOBAL.appConfig().session.session_key,
    store: sessionStore,
    proxy: true,
    cookie: GLOBAL.appConfig().session.cookie
  }));
  if (environment !== "test") {
    app.use(express.csrf());
    app.use(function(req, res, next) {
      res.locals.csrfToken = req.csrfToken();
      next();
    });
    app.use(helmet.xframe('sameorigin'));
    app.use(helmet.hsts());
    app.use(helmet.iexss({setOnOldIE: true}));
    app.use(helmet.ienoopen());
    app.use(helmet.contentTypeOptions());
    app.use(helmet.cacheControl());
  }
  app.use(express.static(__dirname + '/public'));
  app.use(require('connect-assets')(connectAssetsOptions));
  app.use(passport.initialize());
  app.use(passport.session());
  app.use(app.router);
  app.use(function(err, req, res, next) {
    console.error(err);
    res.render("errors/500");
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

require("./lib/sockets")(server, environment, sessionStore, cookieParser);

server.listen(app.get('port'), function(){
  console.log("Coinnext is running on port %d in %s mode", app.get("port"), app.settings.env);
});


//User validation
if (GLOBAL.appConfig().site_auth) {
  var auth = function (req, res, next) {
    if ((req.query.u === GLOBAL.appConfig().site_auth.user) && (req.query.p === GLOBAL.appConfig().site_auth.pass)) {
      req.session.staging_auth = true;
    }
    if (!req.session.staging_auth) return res.redirect("http://www.youtube.com/watch?v=oHg5SJYRHA0");
    next();
  }
  app.get('*', auth);
}


// Routes
require('./routes/site')(app);
require('./routes/auth')(app);
require('./routes/users')(app);
require('./routes/wallets')(app);
require('./routes/payments')(app);
require('./routes/transactions')(app);
require('./routes/orders')(app);
require('./routes/order_logs')(app);
require('./routes/chat')(app);
require('./routes/errors')(app);
require('./routes/api')(app);
