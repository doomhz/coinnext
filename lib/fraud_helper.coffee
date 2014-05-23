MarketHelper = require "./market_helper"
async = require "async"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

FraudHelper =

  findDesyncedWallets: (callback)->
    GLOBAL.db.Wallet.findAll({where: {address: {ne: null}}}).complete (err, wallets)->
      async.mapSeries wallets, FraudHelper.checkProperBalance, (err, result = [])->
        callback err, result.filter (val)->
          val?

  checkProperBalance: (wallet, cb)->
    GLOBAL.db.Transaction.findProcessedByUserAndWallet wallet.user_id, wallet.id, (err, transactions)->
      GLOBAL.db.Payment.findByUserAndWallet wallet.user_id, wallet.id, "processed", (err, payments)->
        options =
          status: "open"
          user_id: wallet.user_id
          sell_currency: wallet.sell_currency
        GLOBAL.db.Order.findByOptions options, (err, orders)->
          totalDeposit = 0
          totalWithdrawal = 0
          totalHoldBalance = 0
          for transaction in transactions
            totalDeposit = math.add totalDeposit, transaction.amount  if transaction.category is "receive"
          for payment in payments
            totalWithdrawal = math.add totalWithdrawal, payment.amount
          for order in orders
            totalHoldBalance = math.add totalHoldBalance, order.left_hold_balance
          totalBalance = math.add totalDeposit, -totalWithdrawal
          totalAvailableBalance = math.add totalBalance, -totalHoldBalance
          return cb()  if totalAvailableBalance is wallet.balance and totalHoldBalance is wallet.hold_balance
          return cb null,
            wallet_id: wallet.id
            user_id: wallet.user_id
            currency: wallet.currency
            current:
              balance: wallet.balance
              hold_balance: wallet.hold_balance
            fixed:
              balance: totalAvailableBalance
              hold_balance: totalHoldBalance

exports = module.exports = FraudHelper