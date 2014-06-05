require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"
MarketHelper = require "./../../../lib/market_helper"
FraudHelper = require "./../../../lib/fraud_helper"

describe "FraudHelper", ->

  beforeEach (done)->
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      GLOBAL.db.Wallet.create({id: 1, user_id: 1, balance: MarketHelper.toBigint(27), hold_balance: MarketHelper.toBigint(60), currency: MarketHelper.getCurrency("LTC")}).success ()->
        walletTransactions = [
          {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(200), category: "receive", balance_loaded: false}
          {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(20), category: "receive", balance_loaded: true}
          {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(20), category: "receive", balance_loaded: true}
          {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(60), category: "receive", balance_loaded: true}
          {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(-60), category: "send", balance_loaded: true}
        ]
        walletPayments = [
          {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(2.999), fee: MarketHelper.toBigint(0.001)}
          {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(6.999), fee: MarketHelper.toBigint(0.001)}
        ]
        orders = [
          {id: 1, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(5), status: "completed"}
          {id: 2, user_id: 1, action: "buy", buy_currency: "LTC", sell_currency: "BTC", amount: MarketHelper.toBigint(2), status: "completed"}
          {id: 3, user_id: 1, action: "sell", buy_currency: "LTC", sell_currency: "BTC", amount: MarketHelper.toBigint(40), status: "open"}
          {id: 4, user_id: 1, action: "sell", buy_currency: "LTC", sell_currency: "BTC", amount: MarketHelper.toBigint(20), status: "open"}
        ]
        orderLogs = [
          {order_id: 1, matched_amount: MarketHelper.toBigint(5), result_amount: MarketHelper.toBigint(0.5), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
          {order_id: 2, matched_amount: MarketHelper.toBigint(2), result_amount: MarketHelper.toBigint(2), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
        ]
        GLOBAL.db.Transaction.bulkCreate(walletTransactions).success ()->
          GLOBAL.db.Payment.bulkCreate(walletPayments).success ()->
            GLOBAL.db.Order.bulkCreate(orders).success ()->
              GLOBAL.db.OrderLog.bulkCreate(orderLogs).success ()->
                done()

  describe "checkWalletBalance", ()->
    it.only "returns the balance difference between the deposits, wihdrawals and orders", (done)->
      FraudHelper.checkWalletBalance 1, (err, result)->
        console.log result
        result.should.eql
          total_received: 100
          total_payed: 10
          total_closed: -3
          balance: 27
          hold_balance: 60
          final_balance: 27
          valid_final_balance: true
        done()
