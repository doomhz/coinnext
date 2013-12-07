exports = mongoose = require('mongoose');
var mongoUri = GLOBAL.appConfig().mongo_uri;
var mongo = GLOBAL.appConfig().mongo;
mongoUri ? mongoose.connect(mongoUri) : mongoose.connect(mongo.host, mongo.db, mongo.port, {user: mongo.user, pass: mongo.pass});
exports = Schema = mongoose.Schema;