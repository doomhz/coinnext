fs = require "fs"
environment = process.env.NODE_ENV or "development"
walletsConfigPath = __dirname + "/wallets_config"
config = JSON.parse(fs.readFileSync(process.cwd() + "/config.json", "utf8"))[environment]
fs.readdirSync(walletsConfigPath).filter((file) ->
  /.json$/.test(file)
).forEach (file) ->
  currency = file.replace ".json", ""
  config.wallets[currency] = JSON.parse fs.readFileSync("#{walletsConfigPath}/#{file}")
  return
exports = module.exports = ()->
  config