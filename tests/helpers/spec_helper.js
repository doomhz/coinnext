var fs = require('fs');
var environment = process.env.NODE_ENV || 'test';
var config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', encoding='utf8'))[environment];

GLOBAL.appConfig = function () {return config;};
GLOBAL.db = require('./../../models/index');
GLOBAL.queue = require('./../../lib/queue/index');

module.exports.should = require("should");