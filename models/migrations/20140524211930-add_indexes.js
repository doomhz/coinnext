(function() {
  module.exports = {
    up: function(migration, DataTypes, done) {
      migration.addIndex("orders", ["deleted_at"]);
      done();
    },
    down: function(migration, DataTypes, done) {
      migration.removeIndex("orders", ["deleted_at"]);
      done();
    }
  };

}).call(this);
