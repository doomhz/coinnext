require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"
MarketHelper = require "./../../../lib/market_helper"

describe "MarketHelper", ->

  ###
  CURRENCIES = [
    "BTC", "LTC", "PPC", "WDC", "NMC", "QRK",
    "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"
  ]
  ###
  CURRENCIES =
    BTC: 1
    LTC: 2
    PPC: 3


  describe "getCurrencies", ()->
    it "returns the available currencies list", ()->
      MarketHelper.getCurrencies().toString().should.equal CURRENCIES.toString()
