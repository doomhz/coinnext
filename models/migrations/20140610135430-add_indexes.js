(function() {
  module.exports = {
    up: function(migration, DataTypes, done) {
      migration.addIndex("payments", ["fraud"]);
      done();
    },
    down: function(migration, DataTypes, done) {
      migration.removeIndex("payments", ["fraud"]);
      done();
    }
  };

}).call(this);
