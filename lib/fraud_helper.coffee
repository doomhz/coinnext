Wallet = GLOBAL.db.Wallet
Transaction = GLOBAL.db.Transaction
Payment = GLOBAL.db.Payment
Order = GLOBAL.db.Order
MarketHelper = require "./market_helper"
async = require "async"
math = require "./math"

FraudHelper =

  checkWalletBalance: (walletId, callback)->
    Wallet.findById walletId, (err, wallet)->
      return callback err  if err
      return callback "Wallet not found."  if not wallet
      FraudHelper.checkBalances wallet, callback

  checkUserBalances: (userId, callback)->
    Wallet.findUserWalletByCurrency userId, "BTC", (err, wallet)->
      return callback err  if err
      return callback "Wallet not found."  if not wallet
      FraudHelper.checkBalances wallet, callback

  checkBalances: (wallet, callback)->
    Transaction.findTotalReceivedByUserAndWallet wallet.user_id, wallet.id, (err, totalReceived)->
      return callback err  if err
      Payment.findTotalPayedByUserAndWallet wallet.user_id, wallet.id, (err, totalPayed)->
        return callback err  if err
        closedOptions =
          status: ["completed", "partiallyCompleted"]
          user_id: wallet.user_id
          currency1: wallet.currency
          include_logs: true
          include_deleted: true
        openOptions =
          status: ["open", "partiallyCompleted"]
          user_id: wallet.user_id
          currency1: wallet.currency
          include_logs: true
        Order.findByOptions closedOptions, (err, closedOrders)->
          Order.findByOptions openOptions, (err, openOrders)->
            closedOrdersBalance = 0
            openOrdersBalance = 0
            for closedOrder in closedOrders
              if closedOrder.action is "sell"
                closedOrdersBalance = parseInt math.subtract(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateSpentFromLogs()))  if closedOrder.sell_currency is wallet.currency
                closedOrdersBalance = parseInt math.add(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateReceivedFromLogs()))  if closedOrder.buy_currency is wallet.currency
              if closedOrder.action is "buy"
                closedOrdersBalance = parseInt math.add(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateReceivedFromLogs()))  if closedOrder.buy_currency is wallet.currency
                closedOrdersBalance = parseInt math.subtract(MarketHelper.toBignum(closedOrdersBalance), MarketHelper.toBignum(closedOrder.calculateSpentFromLogs()))  if closedOrder.sell_currency is wallet.currency
            for openOrder in openOrders
              openOrdersBalance = parseInt math.add(MarketHelper.toBignum(openOrdersBalance), MarketHelper.toBignum(openOrder.left_hold_balance))  if openOrder.sell_currency is wallet.currency
            finalBalance = parseInt math.select(MarketHelper.toBignum(totalReceived)).add(MarketHelper.toBignum(closedOrdersBalance)).subtract(MarketHelper.toBignum(wallet.hold_balance)).subtract(MarketHelper.toBignum(totalPayed)).done()
            result =
              total_received: MarketHelper.fromBigint totalReceived
              total_payed: MarketHelper.fromBigint totalPayed
              total_closed: MarketHelper.fromBigint closedOrdersBalance
              total_open: MarketHelper.fromBigint openOrdersBalance
              balance: MarketHelper.fromBigint wallet.balance
              hold_balance: MarketHelper.fromBigint wallet.hold_balance
              final_balance: MarketHelper.fromBigint finalBalance
              valid_final_balance: finalBalance is wallet.balance
              valid_hold_balance: openOrdersBalance is wallet.hold_balance
            callback err, result

exports = module.exports = FraudHelper