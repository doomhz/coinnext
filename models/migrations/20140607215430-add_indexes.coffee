module.exports =
  up: (migration, DataTypes, done) ->
    migration.addIndex "wallet_health", ["currency"]
    migration.addIndex "wallet_health", ["status"]

    done()
    return

  down: (migration, DataTypes, done) ->
    migration.removeIndex "wallet_health", ["currency"]
    migration.removeIndex "wallet_health", ["status"]

    done()
    return