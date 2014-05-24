require "./../../helpers/spec_helper"
marketStats = require './../../../models/seeds/market_stats'
MarketHelper = require "./../../../lib/market_helper"
auth = require "./../../helpers/auth_helper"

app = require "./../../../app"
walletsEngine = require "./../../../core_api"
request = require "supertest"

beforeEach (done)->
  GLOBAL.db.sequelize.sync({force: true}).complete ()->
    GLOBAL.db.sequelize.query("TRUNCATE TABLE #{GLOBAL.db.MarketStats.tableName}").complete ()->
      GLOBAL.db.MarketStats.bulkCreate(marketStats).complete ()->
        done()

describe "Orders Routes", ->
  describe "POST /orders", ()->
    orderData =
      amount: 5
      buy_currency: "LTC"
      sell_currency: "BTC"
      unit_price: 0.01
      type: "limit"
      action: "buy"

    describe "when the user is not logged in", ()->
      it "returns 409", (done)->
        request(GLOBAL.appConfig().app_host)
        .post("/orders")
        .send(orderData)
        .expect(409)
        .expect({"error": "You need to be logged in to place an order."}, done)

    describe "when the user is logged in", ()->
      describe "when the user is not verified", ()->
        it "returns 409", (done)->
          auth.login {email_verified: false}, (err, cookie)->
            request(GLOBAL.appConfig().app_host)
            .post("/orders")
            .set("cookie", cookie)
            .send(orderData)
            .expect(409)
            .expect({error: "Sorry, but you can not trade. Did you verify your account?"}, done)

      describe "when the user is verified", ()->
        describe "when the wallet doesn't have enough funds", ()->
          it "returns 409", (done)->
            auth.login (err, cookie)->
              request(GLOBAL.appConfig().app_host)
              .post("/orders")
              .set("cookie", cookie)
              .send(orderData)
              .expect(409)
              .expect({error: "Not enough BTC to open an order."}, done)

        describe "when the wallet has enough funds", ()->
          it "returns 200 and the new order", (done)->
            auth.login (err, cookie, user)->
              GLOBAL.db.Wallet.findOrCreateUserWalletByCurrency user.id, "BTC", (err, wallet)->
                wallet.addBalance MarketHelper.toBigint(0.05), null, ()->
                  resultData =
                    id: 1, type: 'limit', action: 'buy', buy_currency: 'LTC', sell_currency: 'BTC',
                    amount: 5, matched_amount: 0, result_amount: 0, fee: 0, unit_price: 0.01, status: 'open',
                    in_queue: true, published: false
                  request(GLOBAL.appConfig().app_host)
                  .post("/orders")
                  .set("cookie", cookie)
                  .send(orderData)
                  .expect(200)
                  .end (err, res)->
                    resultData.updated_at = res.body.updated_at
                    resultData.created_at = res.body.created_at
                    res.body.should.eql resultData
                    done()

          it "puts the balance on hold", (done)->
            auth.login (err, cookie, user)->
              GLOBAL.db.Wallet.findOrCreateUserWalletByCurrency user.id, "BTC", (err, wallet)->
                wallet.addBalance MarketHelper.toBigint(0.05), null, ()->
                  request(GLOBAL.appConfig().app_host)
                  .post("/orders")
                  .set("cookie", cookie)
                  .send(orderData)
                  .end (err, res)->
                    GLOBAL.db.Wallet.findUserWalletByCurrency user.id, "BTC", (err, wallet)->
                      wallet.hold_balance.should.eql MarketHelper.toBigint(0.05)
                      done()

          it "decreases the balance", (done)->
            auth.login (err, cookie, user)->
              GLOBAL.db.Wallet.findOrCreateUserWalletByCurrency user.id, "BTC", (err, wallet)->
                wallet.addBalance MarketHelper.toBigint(0.05), null, ()->
                  request(GLOBAL.appConfig().app_host)
                  .post("/orders")
                  .set("cookie", cookie)
                  .send(orderData)
                  .end (err, res)->
                    GLOBAL.db.Wallet.findUserWalletByCurrency user.id, "BTC", (err, wallet)->
                      wallet.balance.should.eql 0
                      done()

          xit "publishes a order", (done)->
            auth.login (err, cookie, user)->
              GLOBAL.db.Wallet.findOrCreateUserWalletByCurrency user.id, "BTC", (err, wallet)->
                wallet.addBalance MarketHelper.toBigint(0.05), null, ()->
                  request(GLOBAL.appConfig().app_host)
                  .post("/orders")
                  .set("cookie", cookie)
                  .send(orderData)
                  .end (err, res)->
                    GLOBAL.db.Order.find(1).complete (err, order)->
                      order.published.should.eql true
                      done()

          it "opens the order", (done)->
            auth.login (err, cookie, user)->
              GLOBAL.db.Wallet.findOrCreateUserWalletByCurrency user.id, "BTC", (err, wallet)->
                wallet.addBalance MarketHelper.toBigint(0.05), null, ()->
                  request(GLOBAL.appConfig().app_host)
                  .post("/orders")
                  .set("cookie", cookie)
                  .send(orderData)
                  .end (err, res)->
                    GLOBAL.db.Order.find(1).complete (err, order)->
                      order.status.should.eql "open"
                      done()

