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
    DOGE: 4


  describe "getCurrencies", ()->
    it "returns the available currencies list", ()->
      JSON.stringify(MarketHelper.getCurrencies()).should.equal JSON.stringify(CURRENCIES)
