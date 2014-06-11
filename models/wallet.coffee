MarketHelper = require "../lib/market_helper"
_ = require "underscore"
math = require "../lib/math"

module.exports = (sequelize, DataTypes) ->

  Wallet = sequelize.define "Wallet",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      currency:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
        get: ()->
          MarketHelper.getCurrencyLiteral @getDataValue("currency")
        set: (currency)->
          @setDataValue "currency", MarketHelper.getCurrency(currency)
      address:
        type: DataTypes.STRING(34)
        allowNull: true
        unique: true
      balance:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
      hold_balance:
        type: DataTypes.BIGINT.UNSIGNED
        defaultValue: 0
        allowNull: false
        comment: "FLOAT x 100000000"
    ,
      tableName: "wallets"
      getterMethods:

        account: ()->
          "wallet_#{@id}"

        currency_name: ()->
          MarketHelper.getCurrencyName @currency

        fee: ()->
          MarketHelper.getTradeFee()

        withdrawal_fee: ()->
          MarketHelper.getWithdrawalFee @currency

        total_balance: ()->
          parseInt math.add(MarketHelper.toBignum(@balance), MarketHelper.toBignum(@hold_balance))

        network_confirmations: ()->
          MarketHelper.getMinConfirmations @currency

      classMethods:

        findById: (id, callback)->
          Wallet.find(id).complete callback

        findByAddress: (address, callback)->
          Wallet.find({where: {address: address}}).complete callback

        findUserWalletByCurrency: (userId, currency, callback = ()->)->
          Wallet.find({where: {user_id: userId, currency: MarketHelper.getCurrency(currency)}}).complete callback

        findOrCreateUserWalletByCurrency: (userId, currency, callback = ()->)->
          Wallet.findOrCreate({user_id: userId, currency: MarketHelper.getCurrency(currency)}, {user_id: userId, currency: currency}).complete callback

        findUserWallets: (userId, callback = ()->)->
          query =
            where:
              user_id: userId
            order: [
              ["created_at", "DESC"]
            ]
          Wallet.findAll(query).complete (err, wallets = [])->
            wallets = _.sortBy wallets, (w)->
              return " "  if w.currency is "BTC"
              w.currency
            callback err, wallets

        findUserWallet: (userId, walletId, callback = ()->)->
          Wallet.find({where: {user_id: userId, id: walletId}}).complete callback

        findByAccount: (account, callback = ()->)->
          id = account.replace("wallet_", "")
          Wallet.findById id, callback

      instanceMethods:

        getFloat: (attribute)->
          return @[attribute]  if not @[attribute]?
          MarketHelper.fromBigint @[attribute]

        generateAddress: (callback = ()->)->
          GLOBAL.coreAPIClient.send "create_account", [@account, @currency], (err, res, body)=>
            if err
              console.error err
              return callback err, res, body
            if body and body.address
              @address = body.address
              @save().complete callback
            else
              console.error "Could not generate address - #{JSON.stringify(body)}"
              callback "Invalid address"

        addBalance: (newBalance, transaction, callback = ()->)->
          if not _.isNaN(newBalance) and _.isNumber(newBalance)
            @increment({balance: newBalance}, {transaction: transaction}).complete (err, wl)=>
              return callback "Could not add the wallet balance #{newBalance} for #{@id}: #{err}"  if err
              Wallet.find(@id, {transaction: transaction}).complete callback
          else
            callback "Could not add wallet balance #{newBalance} for #{@id}"

        addHoldBalance: (newBalance, transaction, callback = ()->)->
          if not _.isNaN(newBalance) and _.isNumber(newBalance)
            @increment({hold_balance: newBalance}, {transaction: transaction}).complete (err, wl)=>
              return callback "Could not add the wallet hold balance #{newBalance} for #{@id}: #{err}"  if err
              Wallet.find(@id, {transaction: transaction}).complete callback
          else
            callback "Could not add wallet hold balance #{newBalance} for #{@id}"

        holdBalance: (balance, transaction, callback = ()->)->
          if not _.isNaN(balance) and _.isNumber(balance) and @canWithdraw(balance)
            @addBalance -balance, transaction, (err)=>
              if not err
                @addHoldBalance balance, transaction, callback
              else
                callback "Could not hold wallet balance #{balance} for #{@id}, not enough funds?"
          else
            callback "Could not add wallet hold balance #{balance} for #{@id}, invalid balance #{balance}."

        canWithdraw: (amount, includeFee = false)->
          withdrawAmount = parseFloat amount
          withdrawAmount = parseFloat math.add(MarketHelper.toBignum(withdrawAmount), MarketHelper.toBignum(@withdrawal_fee))  if includeFee
          @balance >= withdrawAmount

  Wallet