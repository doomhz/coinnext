require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"

describe "Order", ->
  marketStats = undefined

  beforeEach ->
    marketStats = new MarketStats
  
  afterEach (done)->
    MarketStats.remove ()->
      done()


  describe "calculateGrowthRatio", ()->
    describe "when the last price is 0.2 and the new price is 0.1", ()->
      it "returns -50", ()->
        MarketStats.calculateGrowthRatio(0.2, 0.1).should.eql -50

    describe "when the last price is 2 and the new price is 3", ()->
      it "returns 50", ()->
        MarketStats.calculateGrowthRatio(2, 3).should.eql 50

    describe "when the last price is 2 and the new price is 2.5", ()->
      it "returns 25", ()->
        MarketStats.calculateGrowthRatio(2, 2.5).should.eql 25
