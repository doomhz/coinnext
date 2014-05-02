MarketHelper = require "../../../lib/market_helper"
require "./../../helpers/spec_helper"


describe "Order", ->
  order = undefined

  beforeEach (done)->
    order = GLOBAL.db.Order.build {id: 1, user_id: 1, type: 1, action: 1, buy_currency: "2", sell_currency: "1", amount: 1000000000, unit_price: 10000000, status: 3, published: 1}
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      done()

  describe "inversed_action", ()->
    describe "when the action is buy", ()->
      it "returns sell", ()->
        order.action = "buy"
        order.inversed_action.should.eql "sell"

    describe "when the action is sell", ()->
      it "returns buy", ()->
        order.action = "sell"
        order.inversed_action.should.eql "buy"

    describe "when the action is neither buy or sell", ()->
      it "returns undefined", ()->
        order.action = "other"
        order.inversed_action?.should.not.be.ok
        
  describe "left_amount", ()->
    it "returns the amount minus the matched_amount", ()->
      order.amount = 50
      order.matched_amount = 10
      order.left_amount.should.eql 40

  describe "left_hold_balance", ()->
    describe "when the action is sell", ()->
      it "returns the left_amount", ()->
        order.action = "sell"
        order.amount = 50
        order.matched_amount = 10
        order.left_hold_balance.should.eql 40
    describe "when the action is buy", ()->
      it "returns the left_amount times (unit_price converted to float)", ()->
        order.action = "buy"
        order.amount = 50
        order.matched_amount = 10
        order.unit_price = MarketHelper.toBigint 1.5
        order.left_hold_balance.should.eql 60 # 40 x 1.5

  describe "isValidTradeAmount", ()->
    describe "when amount is not a valid finite number", ()->
      it "returns false", ()->
        GLOBAL.db.Order.isValidTradeAmount(Number.NaN).should.be.false
        GLOBAL.db.Order.isValidTradeAmount(Number.Infinity).should.be.false
        GLOBAL.db.Order.isValidTradeAmount(Number.NEGATIVE_INFINITY).should.be.false
    describe "when amount is a valid finite number", ()->
      describe "but is less than min trade amount", ()->
        it "returns false", ()->
          GLOBAL.db.Order.isValidTradeAmount(MarketHelper.getMinTradeAmount() * 0.99).should.be.false
      describe "and is greater than or equal to min trade amount", ()->
        it "returns true", ()->
          GLOBAL.db.Order.isValidTradeAmount(MarketHelper.getMinTradeAmount()).should.be.true
          GLOBAL.db.Order.isValidTradeAmount(MarketHelper.getMinTradeAmount()* 1.1).should.be.true

  describe "isValidFee", ()->
    describe "when the fee is zero", ()->
      describe "when amount is not a valid finite number", ()->
        it "returns true", ()->
          GLOBAL.db.Order.isValidFee(Number.NaN, "buy", MarketHelper.toBigint(1.5)).should.be.true
          GLOBAL.db.Order.isValidFee(Number.Infinity, "buy", MarketHelper.toBigint(1.5)).should.be.true
          GLOBAL.db.Order.isValidFee(Number.NEGATIVE_INFINITY, "buy", MarketHelper.toBigint(1.5)).should.be.true
  
  describe "isValidSpendAmount", ()->
    describe "when amount is not a valid finite number", ()->
      it "returns false", ()->
        GLOBAL.db.Order.isValidSpendAmount(Number.NaN, "buy", MarketHelper.toBigint(1.5)).should.be.false
        GLOBAL.db.Order.isValidSpendAmount(Number.Infinity, "buy", MarketHelper.toBigint(1.5)).should.be.false
        GLOBAL.db.Order.isValidSpendAmount(Number.NEGATIVE_INFINITY, "buy", MarketHelper.toBigint(1.5)).should.be.false

  describe "isValidReceiveAmount", ()->
    describe "when amount is not a valid finite number", ()->
      it "returns false", ()->
        GLOBAL.db.Order.isValidReceiveAmount(Number.NaN, "buy", MarketHelper.toBigint(1.5)).should.be.false
        GLOBAL.db.Order.isValidReceiveAmount(Number.Infinity, "buy", MarketHelper.toBigint(1.5)).should.be.false
        GLOBAL.db.Order.isValidReceiveAmount(Number.NEGATIVE_INFINITY, "buy", MarketHelper.toBigint(1.5)).should.be.false

  describe "getFloat", ()->
    describe "when there is no such field", ()->
      it "returns undefined", ()->
        order.getFloat("no_such_field")?.should.not.be.ok
    describe "when the field exists", ()->
      it "converts it from bigint to float", ()->
        order.unit_price = MarketHelper.toBigint 1.5
        order.getFloat("unit_price").should.eql 1.5
    describe "when the field is not numeric", ()->
      it "returns undefined", ()->
        console.log order.getFloat("action")
        order.getFloat("action")?.should.not.be.ok

  describe "publish", ()->
    describe "when there is such an order id", ()->
      it "publishes it to the network", ()->
        order.id = 1
        # TODO
        # order.publish ()->
        #   # how to test this?
        #   console.log err
        #   console.dir res
        #   console.dir body
        #   done()

  describe "cancel", ()->
    # TODO
