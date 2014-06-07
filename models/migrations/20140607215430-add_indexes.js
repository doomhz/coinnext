(function() {
  module.exports = {
    up: function(migration, DataTypes, done) {
      migration.addIndex("wallet_health", ["currency"]);
      migration.addIndex("wallet_health", ["status"]);
      done();
    },
    down: function(migration, DataTypes, done) {
      migration.removeIndex("wallet_health", ["currency"]);
      migration.removeIndex("wallet_health", ["status"]);
      done();
    }
  };

}).call(this);
