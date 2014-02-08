_str = require "underscore.string"

_str.satoshiRound = (number)->
    Math.round(number * 100000000) / 100000000

_str.roundToTwo = (number)->
    Math.round(parseFloat(number) * 100) / 100

_str.roundToThree = (number)->
    Math.round(parseFloat(number) * 1000) / 1000

exports = module.exports = _str