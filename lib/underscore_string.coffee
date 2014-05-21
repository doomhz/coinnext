_str = require "underscore.string"

_str.roundTo = (number, decimals = 8)->
  multiplier = Math.pow(10, decimals)
  Math.round(parseFloat(number) * multiplier) / multiplier

_str.satoshiRound = (number)->
  _str.roundTo number, 8

_str.toFixed = (number, decimals = 8)->
  parseFloat(number).toFixed(decimals)

exports = module.exports = _str