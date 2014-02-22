_str = require "underscore.string"

_str.roundTo = (number, decimals = 8)->
  multiplier = Math.pow(10, decimals)
  Math.round(parseFloat(number) * multiplier) / multiplier

_str.satoshiRound = (number)->
  _str.roundTo number, 8

exports = module.exports = _str