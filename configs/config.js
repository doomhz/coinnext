(function() {
  var config, environment, exports, fs, walletsConfigPath;

  fs = require("fs");

  environment = process.env.NODE_ENV || "development";

  walletsConfigPath = __dirname + "/wallets_config";

  config = JSON.parse(fs.readFileSync(process.cwd() + "/config.json", "utf8"))[environment];

  fs.readdirSync(walletsConfigPath).filter(function(file) {
    return /.json$/.test(file);
  }).forEach(function(file) {
    var currency;
    currency = file.replace(".json", "");
    config.wallets[currency] = JSON.parse(fs.readFileSync("" + walletsConfigPath + "/" + file));
  });

  exports = module.exports = function() {
    return config;
  };

}).call(this);
