module.exports =
  up: (migration, DataTypes, done) ->
    migration.addIndex "payments", ["fraud"]

    done()
    return

  down: (migration, DataTypes, done) ->
    migration.removeIndex "payments", ["fraud"]

    done()
    return