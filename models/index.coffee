fs = require("fs")
path = require("path")
Sequelize = require("sequelize")
lodash = require("lodash")

authData = GLOBAL.appConfig().mysql
sequelize = new Sequelize(authData.db, authData.user, authData.password, {port: authData.port})
db = {}

fs.readdirSync(__dirname).filter((file) ->
  (file.indexOf(".") isnt 0) and (file.indexOf(".js") isnt -1) and (file isnt "index.js")
).forEach (file) ->
  model = sequelize.import(path.join(__dirname, file))
  db[model.name] = model
  return

Object.keys(db).forEach (modelName) ->
  db[modelName].associate db  if "associate" of db[modelName]
  return

module.exports = lodash.extend(
  sequelize: sequelize
  Sequelize: Sequelize
, db)