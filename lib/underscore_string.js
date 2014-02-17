(function() {
  var exports, _str;

  _str = require("underscore.string");

  _str.satoshiRound = function(number) {
    return Math.round(number * 100000000) / 100000000;
  };

  _str.roundToTwo = function(number) {
    return Math.round(parseFloat(number) * 100) / 100;
  };

  _str.roundToThree = function(number) {
    return Math.round(parseFloat(number) * 1000) / 1000;
  };

  exports = module.exports = _str;

}).call(this);
