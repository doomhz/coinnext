_ = require "underscore"

module.exports = (sequelize, DataTypes) ->

  #CURRENCIES = [
  #  "BTC", "LTC", "PPC", "WDC", "NMC", "QRK",
  #  "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"
  #]

  CURRENCIES = [
    "BTC", "LTC", "PPC"
  ]

  CURRENCY_NAMES =
    BTC: "Bitcoin"
    LTC: "Litecoin"
    PPC: "Peercoin"

  Wallet = sequelize.define "Wallet",
      user_id:
        type: DataTypes.INTEGER.UNSIGNED
        allowNull: false
      currency:
        type: DataTypes.ENUM
        values: CURRENCIES
        allowNull: false
      address:
        type: DataTypes.STRING
        allowNull: false
      balance:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      hold_balance:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      fee:
        type: DataTypes.FLOAT
        defaultValue: 0.2
        allowNull: false
    ,
      underscored: true
      tableName: "wallets"

      getterMethods:

        account: ()->
          "wallet_#{@id}"

        currency_name: ()->
          CURRENCY_NAMES[@currency]

      classMethods:

        findById: (id, callback)->
          Wallet.find(id).complete callback

        getCurrencies: ()->
          CURRENCIES

        getCurrencyNames: ()->
          CURRENCY_NAMES

        findUserWalletByCurrency: (userId, currency, callback = ()->)->
          Wallet.find({where: {user_id: userId, currency: currency}}).complete callback

        findOrCreateUserWalletByCurrency: (userId, currency, callback = ()->)->
          Wallet.findOrCreate({user_id: userId, currency: currency}, {user_id: userId, currency: currency}).complete callback

        findUserWallets: (userId, callback = ()->)->
          query =
            where:
              user_id: userId
            order: [
              ["created_at", "DESC"]
            ]
          Wallet.findAll(query).complete callback

        findUserWallet: (userId, walletId, callback = ()->)->
          Wallet.find({where: {user_id: userId, id: walletId}}).complete callback

        findByAccount: (account, callback = ()->)->
          id = account.replace("wallet_", "")
          Wallet.findById id, callback

        isValidCurrency: (currency)->
          CURRENCIES.indexOf(currency) > -1
        
      instanceMethods:

        generateAddress: (callback = ()->)->
          GLOBAL.walletsClient.send "create_account", [@account, @currency], (err, res, body)=>
            if err
              console.error err
              return callback err, res, body
            if body and body.address
              @address = body.address
              @save().complete callback
            else
              console.error "Could not generate address - #{JSON.stringify(body)}"
              callback "Invalid address"

        addBalance: (newBalance, callback = ()->)->
          if not _.isNaN(newBalance) and _.isNumber(newBalance)
            @increment({balance: newBalance}).complete (err, wl)=>
              console.log "Could not add the wallet balance #{newBalance} for #{@id}: #{err}"  if err
              callback err, wl
          else
            console.log "Could not add wallet balance #{newBalance} for #{@id}"
            callback(null, @)

        addHoldBalance: (newBalance, callback = ()->)->
          if not _.isNaN(newBalance) and _.isNumber(newBalance)
            @increment({hold_balance: newBalance}).complete (err, wl)=>
              console.log "Could not add the wallet hold balance #{newBalance} for #{@id}: #{err}"  if err
              callback err, wl
          else
            console.log "Could not add wallet hold balance #{newBalance} for #{@id}"
            callback(null, @)

        holdBalance: (balance, callback = ()->)->
          if not _.isNaN(balance) and _.isNumber(balance) and @canWithdraw(balance)
            @addBalance -balance, (err)=>
              if not err
                @addHoldBalance balance, callback
              else
                console.log "Could not hold wallet balance #{balance} for #{@id}, not enough funds?"
                Wallet.findById @id, callback
          else
            console.log "Could not add wallet hold balance #{balance} for #{@id}"
            callback("Invalid balance #{balance}", @)

        canWithdraw: (amount)->
          parseFloat(@balance) >= parseFloat(amount)

  Wallet