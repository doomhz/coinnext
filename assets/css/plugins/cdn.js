var plugin = function(){
  return function(style){
    style.define("CDN", function(imgOptions) {
      var host = GLOBAL.appConfig().assets_host || "";
      var glueSign = imgOptions.string.indexOf("?") > -1 ? "&" : "?";
      var key = GLOBAL.appConfig().assets_key ? glueSign + "_=" + GLOBAL.appConfig().assets_key : "";
      return host + imgOptions.string + key;
    });
  };
};
module.exports = plugin;