module.exports =
  up: (migration, DataTypes, done) ->
    migration.addIndex "order_logs", ["order_id"]
    migration.addIndex "order_logs", ["active"]
    migration.addIndex "order_logs", ["time"]
    migration.addIndex "order_logs", ["status"]
    
    done()
    return

  down: (migration, DataTypes, done) ->
    migration.removeIndex "order_logs", ["order_id"]
    migration.removeIndex "order_logs", ["active"]
    migration.removeIndex "order_logs", ["time"]
    migration.removeIndex "order_logs", ["status"]

    done()
    return