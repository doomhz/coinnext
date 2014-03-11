require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"

describe "Order", ->
  marketStats = undefined

  beforeEach (done)->
    marketStats = GLOBAL.db.MarketStats.build()
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      done()

  describe "calculateGrowthRatio", ()->
    describe "when the last price is 0.2 and the new price is 0.1", ()->
      it "returns -50", ()->
        GLOBAL.db.MarketStats.calculateGrowthRatio(0.2, 0.1).should.eql -50

    describe "when the last price is 2 and the new price is 3", ()->
      it "returns 50", ()->
        GLOBAL.db.MarketStats.calculateGrowthRatio(2, 3).should.eql 50

    describe "when the last price is 2 and the new price is 2.5", ()->
      it "returns 25", ()->
        GLOBAL.db.MarketStats.calculateGrowthRatio(2, 2.5).should.eql 25
