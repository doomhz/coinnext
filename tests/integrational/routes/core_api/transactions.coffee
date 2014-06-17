require "./../../../helpers/spec_helper"
marketStats = require './../../../../models/seeds/market_stats'
MarketHelper = require "./../../../../lib/market_helper"

app = require "./../../../../core_api"
request = require "supertest"

describe "Transactions Api", ->
  wallet = undefined

  beforeEach (done)->
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      GLOBAL.db.sequelize.query("TRUNCATE TABLE #{GLOBAL.db.MarketStats.tableName}").complete ()->
        GLOBAL.db.MarketStats.bulkCreate(marketStats).success ()->
          GLOBAL.db.Wallet.create({currency: "BTC", user_id: 1, address: "address"}).complete (err, wl)->
            wallet = wl
            done()

  describe "PUT /transaction/:currency/:tx_id", ()->
    describe "When there is a valid currency and tx id", ()->
      it "returns 200 ok", (done)->
        request('http://localhost:6000')
        .put("/transaction/BTC/1")
        .send()
        .expect(200)
        .end (e, res = {})->
          throw e if e
          res.body.should.endWith "- Added transaction 1 BTC"
          done()

      describe "when the category is not move", ()->
        it "adds the transaction in the db", (done)->
          request('http://localhost:6000')
          .put("/transaction/BTC/1")
          .send()
          .expect(200)
          .end (e, res = {})->
            throw e if e
            GLOBAL.db.Transaction.find({where: {txid: "unique_tx_id"}}).complete (err, tx)->
              tx.address.should.eql "address"
              done()

        it "loads the transaction amount to the wallet", (done)->
          request('http://localhost:6000')
          .put("/transaction/BTC/1")
          .send()
          .expect(200)
          .expect {}, ()->
            GLOBAL.db.Wallet.findById wallet.id, (err, wl)->
              wl.balance.should.eql MarketHelper.toBigint 1
              done()


  describe "POST /load_latest_transactions/:currency", ()->
    describe "When there is a valid currency and tx id", ()->
      it "returns 200 ok", (done)->
        request('http://localhost:6000')
        .post("/load_latest_transactions/BTC")
        .send()
        .expect(200)
        .end (e, res = {})->
          throw e if e
          res.body.should.endWith "- Processed 1 transactions"
          done()


  describe "POST /process_pending_payments", ()->
    describe "when the wallet has enough balance", ()->
      it "returns 200 ok and the executed payment ids", (done)->
        GLOBAL.db.Transaction.create({amount: MarketHelper.toBigint(20.0002), category: "receive", currency: "BTC", user_id: 1, wallet_id: 1, balance_loaded: true}).complete ()->
          wallet.balance = MarketHelper.toBigint 10
          wallet.save().complete ()->
            GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: MarketHelper.toBigint(10), fee: MarketHelper.toBigint(0.0002), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
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
        GLOBAL.db.Transaction.create({amount: MarketHelper.toBigint(20.0002), category: "receive", currency: "BTC", user_id: 1, wallet_id: 1, balance_loaded: true}).complete ()->
          wallet.balance = MarketHelper.toBigint 10
          wallet.save().complete ()->
            GLOBAL.db.Transaction.create({wallet_id: wallet.id, currency: "BTC", txid: "unique_tx_id_mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, tx)->
              GLOBAL.db.Payment.create({wallet_id: wallet.id, user_id: 1, amount: MarketHelper.toBigint(10), fee: MarketHelper.toBigint(0.0002), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
                request('http://localhost:6000')
                .post("/process_pending_payments")
                .send()
                .expect 200
                .end ()->
                  GLOBAL.db.Transaction.findById tx.id, (e, t)->
                    t.user_id.should.eql 1
                    done()

    describe "when there are payments for the same user", ()->
      it "processes only one payment", (done)->
        GLOBAL.db.Transaction.create({amount: MarketHelper.toBigint(20.0004), category: "receive", currency: "BTC", user_id: 1, wallet_id: 1, balance_loaded: true}).complete ()->
          GLOBAL.db.Transaction.create({amount: MarketHelper.toBigint(10.0002), category: "receive", currency: "BTC", user_id: 2, wallet_id: 2, balance_loaded: true}).complete ()->
            GLOBAL.db.Wallet.create({currency: "BTC", user_id: 2, balance: 0}).complete (err, wallet2)->
              wallet.balance = MarketHelper.toBigint 10
              wallet.save().complete ()->
                GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: MarketHelper.toBigint(5), fee: MarketHelper.toBigint(0.0002), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVa"}).complete (err, pm)->
                  GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: MarketHelper.toBigint(5), fee: MarketHelper.toBigint(0.0002), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVb"}).complete (err2, pm2)->
                    GLOBAL.db.Payment.create({user_id: 2, wallet_id: wallet2.id, amount: MarketHelper.toBigint(10), fee: MarketHelper.toBigint(0.0002), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVc"}).complete (err3, pm3)->
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


  describe "DELETE /cancel_payment/:payment_id", ()->
    it "returns 200 ok and the removed payment id", (done)->
      wallet.balance = 0
      wallet.save().complete ()->
        GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: MarketHelper.toBigint(10), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
          paymentId = pm.id
          request('http://localhost:6000')
          .del("/cancel_payment/#{paymentId}")
          .send()
          .expect(200)
          .end done

    it "deletes the payment", (done)->
      wallet.balance = 0
      wallet.save().complete ()->
        GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: MarketHelper.toBigint(10), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
          paymentId = pm.id
          request('http://localhost:6000')
          .del("/cancel_payment/#{paymentId}")
          .send()
          .expect(200)
          .end (e, res = {})->
            throw e if e
            GLOBAL.db.Payment.findAndCountAll({where: {id: paymentId}}).complete (err, result)->
              result.count.should.eql 0
              done()

    it "refunds the user wallet adding the transaction fee", (done)->
      wallet.balance = 0
      wallet.save().complete ()->
        GLOBAL.db.Payment.create({user_id: 1, wallet_id: wallet.id, amount: MarketHelper.toBigint(10), currency: "BTC", address: "mrLpnPMsKR8oFqRRYA28y4Txu98TUNQzVw"}).complete (err, pm)->
          paymentId = pm.id
          totalWithdrawalAmount = wallet.withdrawal_fee + pm.amount
          request('http://localhost:6000')
          .del("/cancel_payment/#{paymentId}")
          .send()
          .expect(200)
          .end (e, res = {})->
            throw e if e
            GLOBAL.db.Wallet.find(wallet.id).complete (err, wallet)->
              wallet.balance.should.eql totalWithdrawalAmount
              done()
