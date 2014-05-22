module.exports =
  up: (migration, DataTypes, done) ->
    migration.addIndex "events", ["status"]
    migration.addIndex "events", ["created_at"]

    done()
    return

  down: (migration, DataTypes, done) ->
    migration.removeIndex "events", ["status"]
    migration.removeIndex "events", ["created_at"]

    done()
    return