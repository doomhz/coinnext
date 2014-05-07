(function() {
  module.exports = {
    up: function(migration, DataTypes, done) {
      migration.changeColumn("market_stats", "growth_ratio", {
        type: DataTypes.BIGINT,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      });
      done();
    },
    down: function(migration, DataTypes, done) {
      migration.changeColumn("market_stats", "growth_ratio", {
        type: DataTypes.BIGINT.UNSIGNED,
        defaultValue: 0,
        allowNull: false,
        comment: "FLOAT x 100000000"
      });
      done();
    }
  };

}).call(this);
