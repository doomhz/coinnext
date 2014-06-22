require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"
MarketHelper = require "./../../../lib/market_helper"
FraudHelper = require "./../../../lib/fraud_helper"

describe "FraudHelper", ->

  beforeEach (done)->
    done()

  describe "checkWalletBalance", ()->
    describe "when the current balance matches and the hold balance matches", ()->
      beforeEach (done)->
        GLOBAL.db.sequelize.sync({force: true}).complete ()->
          GLOBAL.db.Wallet.create({id: 1, user_id: 1, balance: MarketHelper.toBigint(27), hold_balance: MarketHelper.toBigint(45), currency: "LTC"}).success ()->
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
              {id: 3, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(40), matched_amount: MarketHelper.toBigint(15), status: "partiallyCompleted"}
              {id: 4, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(20), status: "open"}
            ]
            orderLogs = [
              {order_id: 1, matched_amount: MarketHelper.toBigint(5), result_amount: MarketHelper.toBigint(0.5), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {order_id: 2, matched_amount: MarketHelper.toBigint(2), result_amount: MarketHelper.toBigint(2), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {order_id: 3, matched_amount: MarketHelper.toBigint(15), result_amount: MarketHelper.toBigint(1.5), unit_price: MarketHelper.toBigint(0.1), status: "partiallyCompleted"}
            ]
            GLOBAL.db.Transaction.bulkCreate(walletTransactions).success ()->
              GLOBAL.db.Payment.bulkCreate(walletPayments).success ()->
                GLOBAL.db.Order.bulkCreate(orders).success ()->
                  GLOBAL.db.OrderLog.bulkCreate(orderLogs).success ()->
                    done()

      it "returns the balance difference between the deposits, wihdrawals and orders", (done)->
        FraudHelper.checkWalletBalance 1, (err, result)->
          result.should.eql
            total_received: 100
            total_payed: 10
            total_closed: -18
            total_open: 45
            balance: 27
            hold_balance: 45
            final_balance: 27
            valid_final_balance: true
            valid_hold_balance: true
          done()


    describe "when the current balance does not match", ()->
      beforeEach (done)->
        GLOBAL.db.sequelize.sync({force: true}).complete ()->
          GLOBAL.db.Wallet.create({id: 1, user_id: 1, balance: MarketHelper.toBigint(2.6), hold_balance: MarketHelper.toBigint(0.2), currency: "BTC"}).success ()->
            walletTransactions = [
              {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(0.3), category: "receive", balance_loaded: false}
              {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(0.5), category: "receive", balance_loaded: true}
              {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(0.4), category: "receive", balance_loaded: true}
              {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(0.6), category: "receive", balance_loaded: true}
              {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(-0.5), category: "send", balance_loaded: true}
            ]
            walletPayments = [
              {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(0.299), fee: MarketHelper.toBigint(0.001)}
              {wallet_id: 1, user_id: 1, amount: MarketHelper.toBigint(0.199), fee: MarketHelper.toBigint(0.001)}
            ]
            orders = [
              {id: 1, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(5), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {id: 2, user_id: 1, action: "buy", buy_currency: "LTC", sell_currency: "BTC", amount: MarketHelper.toBigint(2), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {id: 3, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(40), matched_amount: MarketHelper.toBigint(15), unit_price: MarketHelper.toBigint(0.1), status: "partiallyCompleted"}
              {id: 4, user_id: 1, action: "buy", buy_currency: "LTC", sell_currency: "BTC", amount: MarketHelper.toBigint(20), unit_price: MarketHelper.toBigint(0.01), status: "open"}
            ]
            orderLogs = [
              {order_id: 1, matched_amount: MarketHelper.toBigint(5), result_amount: MarketHelper.toBigint(0.5), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {order_id: 2, matched_amount: MarketHelper.toBigint(2), result_amount: MarketHelper.toBigint(2), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {order_id: 3, matched_amount: MarketHelper.toBigint(15), result_amount: MarketHelper.toBigint(1.5), unit_price: MarketHelper.toBigint(0.1), status: "partiallyCompleted"}
            ]
            GLOBAL.db.Transaction.bulkCreate(walletTransactions).success ()->
              GLOBAL.db.Payment.bulkCreate(walletPayments).success ()->
                GLOBAL.db.Order.bulkCreate(orders).success ()->
                  GLOBAL.db.OrderLog.bulkCreate(orderLogs).success ()->
                    done()

      it "returns the balance difference between the deposits, wihdrawals and orders", (done)->
        FraudHelper.checkWalletBalance 1, (err, result)->
          result.should.eql
            total_received: 1.5
            total_payed: 0.5
            total_closed: 1.8
            total_open: 0.2
            balance: 2.6
            hold_balance: 0.2
            final_balance: 2.6
            valid_final_balance: true
            valid_hold_balance: true
          done()


    describe "when there is a partiallyCompleted deleted order", ()->
      beforeEach (done)->
        GLOBAL.db.sequelize.sync({force: true}).complete ()->
          GLOBAL.db.Wallet.create({id: 1, user_id: 1, balance: MarketHelper.toBigint(27), hold_balance: MarketHelper.toBigint(45), currency: "LTC"}).success ()->
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
              {id: 1, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(3), status: "completed"}
              {id: 2, user_id: 1, action: "buy", buy_currency: "LTC", sell_currency: "BTC", amount: MarketHelper.toBigint(2), status: "completed"}
              {id: 3, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(40), matched_amount: MarketHelper.toBigint(15), status: "partiallyCompleted"}
              {id: 4, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(20), status: "open"}
              {id: 5, user_id: 1, action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: MarketHelper.toBigint(5), matched_amount: MarketHelper.toBigint(2), status: "partiallyCompleted", deleted_at: Date.now()}
            ]
            orderLogs = [
              {order_id: 1, matched_amount: MarketHelper.toBigint(3), result_amount: MarketHelper.toBigint(0.3), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {order_id: 2, matched_amount: MarketHelper.toBigint(2), result_amount: MarketHelper.toBigint(2), unit_price: MarketHelper.toBigint(0.1), status: "completed"}
              {order_id: 3, matched_amount: MarketHelper.toBigint(15), result_amount: MarketHelper.toBigint(1.5), unit_price: MarketHelper.toBigint(0.1), status: "partiallyCompleted"}
              {order_id: 5, matched_amount: MarketHelper.toBigint(2), result_amount: MarketHelper.toBigint(0.2), unit_price: MarketHelper.toBigint(0.1), status: "partiallyCompleted"}
            ]
            GLOBAL.db.Transaction.bulkCreate(walletTransactions).success ()->
              GLOBAL.db.Payment.bulkCreate(walletPayments).success ()->
                GLOBAL.db.Order.bulkCreate(orders).success ()->
                  GLOBAL.db.OrderLog.bulkCreate(orderLogs).success ()->
                    done()

      it "returns the balance difference between the deposits, wihdrawals and orders", (done)->
        FraudHelper.checkWalletBalance 1, (err, result)->
          result.should.eql
            total_received: 100
            total_payed: 10
            total_closed: -18
            total_open: 45
            balance: 27
            hold_balance: 45
            final_balance: 27
            valid_final_balance: true
            valid_hold_balance: true
          done()