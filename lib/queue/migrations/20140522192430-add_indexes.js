(function() {
  module.exports = {
    up: function(migration, DataTypes, done) {
      migration.addIndex("events", ["status"]);
      migration.addIndex("events", ["created_at"]);
      done();
    },
    down: function(migration, DataTypes, done) {
      migration.removeIndex("events", ["status"]);
      migration.removeIndex("events", ["created_at"]);
      done();
    }
  };

}).call(this);
