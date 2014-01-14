require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"

describe "Order", ->
  order = undefined

  beforeEach ->
    order = new Order
  
  afterEach (done)->
    Order.remove ()->
      done()


  describe "when it is a limit order without a unit price", ()->
    xit "returns false", (done)->
      order.save ()->
        console.log arguments
        done()
