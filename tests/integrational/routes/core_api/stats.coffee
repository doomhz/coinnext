require "./../../../helpers/spec_helper"
MarketHelper = require "./../../../../lib/market_helper"

app = require "./../../../../core_api"
request = require "supertest"

describe "Stats Api", ->

  beforeEach (done)->
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      GLOBAL.db.sequelize.query("TRUNCATE TABLE #{GLOBAL.db.MarketStats.tableName}").complete ()->
        done()

  describe "POST /trade_stats", ()->
    now = Date.now()
    halfHour = 1800000
    endTime =  now - now % halfHour
    startTime = endTime - halfHour
    beforeEach (done)->
      orders = [
        {id: 1, user_id: 1, type: "limit", action: "buy", buy_currency: "LTC", sell_currency: "BTC", unit_price: MarketHelper.toBigint(0.1), status: "completed", published: true, close_time: startTime + 60000}
        
        {id: 2, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", unit_price: MarketHelper.toBigint(0.99999), status: "completed", published: true, close_time: startTime - 1}

        {id: 3, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", unit_price: MarketHelper.toBigint(0.2), status: "completed", published: true, close_time: startTime + 130000}
        {id: 4, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", unit_price: MarketHelper.toBigint(0.5), status: "completed", published: true, close_time: startTime + 150000}
        {id: 5, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", unit_price: MarketHelper.toBigint(0.95), status: "completed", published: true, close_time: startTime + 170000}
        {id: 6, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", unit_price: MarketHelper.toBigint(0.01), status: "completed", published: true, close_time: startTime + 190000}

        {id: 7, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", unit_price: MarketHelper.toBigint(0.5), status: "completed", published: true, close_time: startTime + 130000}
        {id: 8, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", unit_price: MarketHelper.toBigint(0.23), status: "completed", published: true, close_time: startTime + 150000}
        {id: 9, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", unit_price: MarketHelper.toBigint(0.56), status: "completed", published: true, close_time: startTime + 170000}
        {id: 10, user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", unit_price: MarketHelper.toBigint(0.07), status: "completed", published: true, close_time: startTime + 190000}
      ]
      orderLogs = [
        {order_id: 1, matched_amount: MarketHelper.toBigint(10), result_amount: MarketHelper.toBigint(10), unit_price: MarketHelper.toBigint(0.1), status: "completed", time: startTime + 60000}
        
        {order_id: 2, matched_amount: MarketHelper.toBigint(1000), result_amount: MarketHelper.toBigint(999.99), unit_price: MarketHelper.toBigint(0.99999), status: "completed", time: startTime - 1}

        {order_id: 3, matched_amount: MarketHelper.toBigint(5), result_amount: MarketHelper.toBigint(1), unit_price: MarketHelper.toBigint(0.2), status: "completed", time: startTime + 130000}
        {order_id: 4, matched_amount: MarketHelper.toBigint(5), result_amount: MarketHelper.toBigint(12.5), unit_price: MarketHelper.toBigint(0.5), status: "completed", time: startTime + 150000}
        {order_id: 5, matched_amount: MarketHelper.toBigint(5), result_amount: MarketHelper.toBigint(23.75), unit_price: MarketHelper.toBigint(0.95), status: "completed", time: startTime + 170000}
        {order_id: 6, matched_amount: MarketHelper.toBigint(5), result_amount: MarketHelper.toBigint(0.25), unit_price: MarketHelper.toBigint(0.01), status: "completed", time: startTime + 190000}

        {order_id: 7, matched_amount: MarketHelper.toBigint(300000000), result_amount: MarketHelper.toBigint(150000000), unit_price: MarketHelper.toBigint(0.5), status: "completed", time: startTime + 130000}
        {order_id: 8, matched_amount: MarketHelper.toBigint(100000000), result_amount: MarketHelper.toBigint(23000000), unit_price: MarketHelper.toBigint(0.23), status: "completed", time: startTime + 150000}
        {order_id: 9, matched_amount: MarketHelper.toBigint(3000000), result_amount: MarketHelper.toBigint(1680000), unit_price: MarketHelper.toBigint(0.56), status: "completed", time: startTime + 170000}
        {order_id: 10, matched_amount: MarketHelper.toBigint(2000000), result_amount: MarketHelper.toBigint(140000), unit_price: MarketHelper.toBigint(0.07), status: "completed", time: startTime + 190000}
      ]
      GLOBAL.db.Order.bulkCreate(orders).complete ()->
        GLOBAL.db.OrderLog.bulkCreate(orderLogs).complete ()->
          done()

    it "returns 200 ok", (done)->
      request('http://localhost:6000')
      .post("/trade_stats")
      .send()
      .expect(200)
      .end (err, res)->
        res.body.message.should.eql "Trade stats aggregated from #{new Date(startTime)} to #{new Date(endTime)}"
        done()

    it "returns the aggregated order result", (done)->
      request('http://localhost:6000')
      .post("/trade_stats")
      .send()
      .expect(200)
      .end (err, res)->
        expectedResult = [
          {
            type: "LTC_BTC"
            open_price: MarketHelper.toBigint 0.2
            close_price: MarketHelper.toBigint 0.01
            high_price: MarketHelper.toBigint 0.95
            low_price: MarketHelper.toBigint 0.01
            volume: MarketHelper.toBigint 20
            exchange_volume: MarketHelper.toBigint 37.5
            start_time: new Date(startTime).toISOString()
            end_time: new Date(endTime).toISOString()
            id: null
          }
          {
            type: "DOGE_BTC"
            open_price: MarketHelper.toBigint 0.5
            close_price: MarketHelper.toBigint 0.07
            high_price: MarketHelper.toBigint 0.56
            low_price: MarketHelper.toBigint 0.07
            volume: MarketHelper.toBigint 405000000
            exchange_volume: MarketHelper.toBigint 174820000
            start_time: new Date(startTime).toISOString()
            end_time: new Date(endTime).toISOString()
            id: null
          }
        ]
        res.body.result.should.eql expectedResult
        done()

    it "aggregates the orders from the last half an hour and persists them", (done)->
      request('http://localhost:6000')
      .post("/trade_stats")
      .send()
      .expect(200)
      .end ()->
        GLOBAL.db.TradeStats.findAll().complete (err, tradeStats)->
          expected =
            1: {id: 1, type: "LTC_BTC", open_price: MarketHelper.toBigint 0.2, close_price: MarketHelper.toBigint 0.01, high_price: MarketHelper.toBigint 0.95, low_price: MarketHelper.toBigint 0.01, volume: MarketHelper.toBigint 20, exchange_volume: MarketHelper.toBigint 37.5, start_time: new Date(startTime), end_time: new Date(endTime)}
            2: {id: 2, type: "DOGE_BTC", open_price: MarketHelper.toBigint 0.5, close_price: MarketHelper.toBigint 0.07, high_price: MarketHelper.toBigint 0.56, low_price: MarketHelper.toBigint 0.07, volume: MarketHelper.toBigint 405000000, exchange_volume: MarketHelper.toBigint 174820000, start_time: new Date(startTime), end_time: new Date(endTime)}
          for stat in tradeStats
            stat.values.should.containEql expected[stat.id]
          done()
