require "./../../../helpers/spec_helper"

app = require "./../../../../wallets"
request = require "supertest"

describe "Trading Api", ->
  describe "PUT /complete_order/:order_id", ()->
    describe "When there is a valid order id", ()->
      it "returns 200 ok", (done)->
        request('http://localhost:6000')
        .put("/complete_order/1")
        .send({eventData: {status: true}})
        .expect(200)
        .expect({id: 1, status: "complete"}, done)