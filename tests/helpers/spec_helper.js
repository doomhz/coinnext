var fs = require('fs');
var environment = process.env.NODE_ENV || 'development';
var config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', encoding='utf8'))[environment];

GLOBAL.appConfig = function () {return config;};

require('./../../models/db_connect_mongo');
GLOBAL.User = require('./../../models/user');

module.exports.should = require("should");