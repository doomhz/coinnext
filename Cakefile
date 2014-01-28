fs = require "fs"
environment = process.env.NODE_ENV or 'development'
config = JSON.parse(fs.readFileSync(process.cwd() + '/config.json', 'utf8'))[environment]
GLOBAL.appConfig = ()-> config
ClientSocket = require "./lib/client_socket"
userSocket = new ClientSocket

task "db:ensure_indexes", "Create indexes for all the collections", ()->
  require('./models/db_connect_mongo')
  _s         = require "underscore.string"
  modelNames = ["User"]
  for modelName in modelNames
    model = require "./models/#{_s.underscored(modelName)}"
    model.ensureIndexes()
