require "./../../../helpers/spec_helper"
marketStats = require './../../../../models/seeds/market_stats'

app = require "./../../../../wallets"
request = require "supertest"

describe "Transactions Api", ->
  wallet = undefined

  beforeEach (done)->
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      GLOBAL.db.sequelize.query("TRUNCATE TABLE #{GLOBAL.db.MarketStats.tableName}").complete ()->
        GLOBAL.db.MarketStats.bulkCreate(marketStats).success ()->
          GLOBAL.db.Wallet.create({currency: "BTC", user_id: 1}).complete (err, wl)->
            wallet = wl
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
            GLOBAL.db.Transaction.findByTxid "unique_tx_id", (err, tx)->
              tx.account.should.eql "account"
              done()

        xit "loads the transaction amount to the wallet", (done)->
          request('http://localhost:6000')
          .put("/transaction/BTC/1")
          .send()
          .expect(200)
          .expect {}, ()->
            GLOBAL.db.Wallet.findById wallet.id, (err, wl)->
              wl.balance.should.eql 1
              done()

  describe "POST /process_pending_payments", ()->
    describe "when the wallet has enough balance", ()->
      it "returns 200 ok and the executed payment ids", (done)->
        wallet.balance = 10
        wallet.save().complete ()->
          GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: 10, currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
            request('http://localhost:6000')
            .post("/process_pending_payments")
            .send()
            .expect(200)
            .end (e, res = {})->
              throw e if e
              res.body.should.endWith "#{pm.id} - processed"
              GLOBAL.db.Payment.findById pm.id, (e, p)->
                p.status.should.eql "processed"
                done()

      it "updates the user_id from the payment", (done)->
        wallet.balance = 10
        wallet.save().complete ()->
          GLOBAL.db.Transaction.create({wallet_id: wallet.id, currency: "BTC", txid: "unique_tx_id_mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, tx)->
            GLOBAL.db.Payment.create({wallet_id: wallet.id, user_id: 1, amount: 10, currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
              request('http://localhost:6000')
              .post("/process_pending_payments")
              .send()
              .expect 200
              .end ()->
                GLOBAL.db.Transaction.findById tx.id, (e, t)->
                  t.user_id.should.eql 1
                  done()

    describe "when the wallet does not have enough balance", ()->
      it "returns 200 ok and the non executed payment ids", (done)->
        GLOBAL.db.Payment.create({wallet_id: wallet.id, amount: 10, currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
          request('http://localhost:6000')
          .post("/process_pending_payments")
          .send()
          .expect(200)
          .end (e, res)->
            throw e if e
            res.body.should.endWith "#{pm.id} - not processed - no funds"
            GLOBAL.db.Payment.findById pm.id, (e, p)->
              p.status.should.eql "pending"
              done()

    describe "when there are payments for the same user", ()->
      it "processes only one payment", (done)->
        GLOBAL.db.Wallet.create({currency: "BTC", user_id: 2, balance: 10}).complete (err, wallet2)->
          wallet.balance = 10
          wallet.save().complete ()->
            GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: 5, currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVa"}).complete (err, pm)->
              GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: 5, currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVb"}).complete (err2, pm2)->
                GLOBAL.db.Payment.create({user_id: 2, wallet_id: wallet2.id, amount: 10, currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVc"}).complete (err3, pm3)->
                  request('http://localhost:6000')
                  .post("/process_pending_payments")
                  .send()
                  .expect(200)
                  .end (e, res = {})->
                    throw e if e
                    res.body.should.endWith "#{pm.id} - processed,#{pm2.id} - user already had a processed payment,#{pm3.id} - processed"
                    GLOBAL.db.Payment.findById pm.id, (e, p1)->
                      GLOBAL.db.Payment.findById pm2.id, (e, p2)->
                        GLOBAL.db.Payment.findById pm3.id, (e, p3)->
                          [p1.status, p2.status, p3.status].toString().should.eql "processed,pending,processed"
                          done()
