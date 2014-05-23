(function() {
  var Sequelize, authData, db, fs, lodash, path, sequelize;

  fs = require("fs");

  path = require("path");

  Sequelize = require("sequelize");

  lodash = require("lodash");

  authData = GLOBAL.appConfig().mysql;

  sequelize = new Sequelize(authData.db, authData.user, authData.password, {
    port: authData.port,
    host: authData.host,
    logging: authData.logging,
    maxConcurrentQueries: 100,
    define: {
      underscored: true,
      freezeTableName: false,
      syncOnAssociation: true,
      charset: "utf8",
      collate: "utf8_general_ci",
      timestamps: true
    },
    pool: {
      maxConnections: 151,
      maxIdleTime: 30
    }
  });

  db = {};

  fs.readdirSync(__dirname).filter(function(file) {
    return (file.indexOf(".") !== 0) && (file.indexOf(".js") !== -1) && (file !== "index.js") && (file !== "associations.js");
  }).forEach(function(file) {
    var model;
    model = sequelize["import"](path.join(__dirname, file));
    db[model.name] = model;
  });

  Object.keys(db).forEach(function(modelName) {
    if ("associate" in db[modelName]) {
      db[modelName].associate(db);
    }
  });

  db.User.hasMany(db.Chat);

  db.User.hasMany(db.UserToken);

  db.User.hasMany(db.Transaction);

  db.Chat.belongsTo(db.User);

  db.Transaction.belongsTo(db.User);

  db.UserToken.belongsTo(db.User);

  db.Payment.hasMany(db.PaymentLog);

  db.PaymentLog.belongsTo(db.Payment);

  db.Order.hasMany(db.OrderLog);

  db.OrderLog.belongsTo(db.Order);

  module.exports = lodash.extend({
    sequelize: sequelize,
    Sequelize: Sequelize
  }, db);

}).call(this);
