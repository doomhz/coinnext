module.exports =
  up: (migration, DataTypes, done) ->
    migration.addIndex "orders", ["deleted_at"]

    done()
    return

  down: (migration, DataTypes, done) ->
    migration.removeIndex "orders", ["deleted_at"]

    done()
    return