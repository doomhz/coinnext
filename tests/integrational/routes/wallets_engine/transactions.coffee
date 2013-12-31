require "./../../../helpers/spec_helper"

app = require "./../../../../wallets"
request = require "supertest"

describe "Transactions Api", ->
  wallet = undefined

  beforeEach (done)->
    Wallet.create {currency: "BTC", user_id: "user_id"}, (err, wl)->
      wallet = wl
      done()

  afterEach (done)->
    Transaction.remove ()->
      Wallet.remove ()->
        Payment.remove ()->
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

  describe "POST /process_pending_payments", ()->
    describe "when the wallet has enough balance", ()->
      it "returns 200 ok and the executed payment ids", (done)->
        wallet.balance = 10
        wallet.save ()->
          Payment.create {wallet_id: wallet.id, amount: 10, currency: "BTC"}, (err, pm)->
            request('http://localhost:6000')
            .post("/process_pending_payments")
            .send()
            .expect(200)
            .expect(["#{pm.id} - processed"], done)

    describe "when the wallet does not have enough balance", ()->
      it "returns 200 ok and the non executed payment ids", (done)->
        Payment.create {wallet_id: wallet.id, amount: 10, currency: "BTC"}, (err, pm)->
          request('http://localhost:6000')
          .post("/process_pending_payments")
          .send()
          .expect(200)
          .expect(["#{pm.id} - not processed - no funds"], done)

    describe "when there are payments for the same user", ()->
      it "processes only one payment", (done)->
        Wallet.create {currency: "BTC", user_id: "user_id2", balance: 10}, (err, wallet2)->
          wallet.balance = 10
          wallet.save ()->
            Payment.create {wallet_id: wallet.id, amount: 5, currency: "BTC"}, (err, pm)->
              Payment.create {wallet_id: wallet.id, amount: 5, currency: "BTC"}, (err, pm2)->
                Payment.create {wallet_id: wallet2.id, amount: 10, currency: "BTC"}, (err, pm3)->
                  request('http://localhost:6000')
                  .post("/process_pending_payments")
                  .send()
                  .expect(200)
                  .expect(["#{pm.id} - processed", "#{pm2.id} - user already had a processed payment", "#{pm3.id} - processed"], done)
