require "./../../../helpers/spec_helper"

app = require "./../../../../wallets"
request = require "supertest"

describe "Transactions Api", ->
  wallet          = undefined

  beforeEach (done)->
    Wallet.create {_id: "account", currency: "BTC", user_id: "user_id"}, (err, wl)->
      wallet = wl
      done()

  afterEach (done)->
    Transaction.remove ()->
      Wallet.remove ()->
        done()

  describe "PUT /transaction/:currency/:tx_id", ()->
    describe "When there is a valid currency and tx id", ()->
      it "returns 200 ok", (done)->
        request('http://localhost:6000')
        .put("/transaction/BTC/1")
        .send()
        .expect(200)
        .expect({}, done)

      describe "when the category is not move", ()->
        it "adds the transaction in the db", (done)->
          request('http://localhost:6000')
          .put("/transaction/BTC/1")
          .send()
          .expect(200)
          .expect {}, ()->
            Transaction.findOne {txid: "unique_tx_id"}, (err, tx)->
              tx.account.should.eql "account"
              done()

        xit "loads the transaction amount to the wallet", (done)->
          request('http://localhost:6000')
          .put("/transaction/BTC/1")
          .send()
          .expect(200)
          .expect {}, ()->
            Wallet.findById wallet.id, (err, wl)->
              wl.balance.should.eql 1
              done()

