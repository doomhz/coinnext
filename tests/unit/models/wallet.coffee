require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"

describe "Wallet", ->
  wallet = undefined
  ###
  CURRENCIES = [
    "BTC", "LTC", "PPC", "WDC", "NMC", "QRK",
    "NVC", "ZET", "FTC", "XPM", "MEC", "TRC"
  ]
  ###
  CURRENCIES = [
    "BTC", "LTC", "PPC"
  ]

  beforeEach (done)->
    GLOBAL.walletsClient =
      send: (action, data, callback)->
        if action is "create_account"
          return callback null, null, {address: "address_#{data[0]}_#{data[1]}"}
        return callback "Unknown action"
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      GLOBAL.db.Wallet.create({currency: "BTC", user_id: 1}).complete (err, wl)->
        wallet = wl
        done()
  
  afterEach ()->
    GLOBAL.walletsClient = undefined


  describe "account", ()->
    it "returns a virtual wallet account", ()->
      wallet.account.should.eql "wallet_#{wallet.id}"


  describe "generateAddress", ()->
    it "sets a new wallet address", (done)->
      wallet.generateAddress (err, wl)->
        wl.address.should.eql "address_#{wallet.account}_#{wallet.currency}"
        done()


  describe "addBalance", ()->
    it "adds the balance to the wallet", (done)->
      wallet.balance = 0
      wallet.save().complete (err, wl)->
        wl.addBalance 3, null, (err, syncedWallet)->
          syncedWallet.balance.should.eql 3
          done()


  describe "canWithdraw", ()->
    beforeEach ()->
      wallet.balance = 10

    describe "when the balance is bigger than the given amount", ()->
      it "returns true", ()->
        wallet.canWithdraw(9).should.be.true

    describe "when the balance is equal to the given amount", ()->
      it "returns true", ()->
        wallet.canWithdraw(10).should.be.true

    describe "when the balance is lower than the given amount", ()->
      it "returns false", ()->
        wallet.canWithdraw(10.001).should.be.false


  describe "findUserWalletByCurrency", ()->
    savedWalletId = undefined
    
    beforeEach (done)->
      GLOBAL.db.Wallet.create({user_id: "user_id", currency: "BTC"}).complete (err, wl)->
        savedWalletId = wl.id
        GLOBAL.db.Wallet.create({user_id: "user_id", currency: "LTC"}).complete ()->
          GLOBAL.db.Wallet.create({user_id: "user_id2", currency: "LTC"}).complete ()->
            done()

    describe "when there is a wallet for the given user with the given currency", ()->
      it "returns the first wallet with the given user id and currency", (done)->
        GLOBAL.db.Wallet.findUserWalletByCurrency "user_id", "BTC", (err, wl)->
          wl.id.should.eql savedWalletId
          done()


  describe "findUserWallets", ()->
    beforeEach (done)->
      GLOBAL.db.Wallet.create({user_id: 2, currency: "BTC", created: Date.now() - 1000}).complete (err, wl)->
        GLOBAL.db.Wallet.create({user_id: 2, currency: "LTC", created: Date.now()}).complete ()->
          GLOBAL.db.Wallet.create({user_id: 3, currency: "LTC"}).complete ()->
            done()

    it "returns the user wallets", (done)->
      GLOBAL.db.Wallet.findUserWallets 2, (err, wallets)->
        wallets.length.should.eql 2
        done()

    it "orders the wallets desc by created", (done)->
      GLOBAL.db.Wallet.findUserWallets 2, (err, wallets)->
        [wallets[0].currency, wallets[1].currency].toString().should.eql ["BTC", "LTC"].toString()
        done()


  describe "findUserWallet", ()->
    savedWalletId = undefined
    
    beforeEach (done)->
      GLOBAL.db.Wallet.create({user_id: 2, currency: "BTC"}).complete ()->
        GLOBAL.db.Wallet.create({user_id: 2, currency: "LTC"}).complete (err, wl)->
          savedWalletId = wl.id
          GLOBAL.db.Wallet.create({user_id: 3, currency: "LTC"}).complete ()->
            done()

    it "returns the user wallet by the given user id and wallet id", (done)->
      GLOBAL.db.Wallet.findUserWallet 2, savedWalletId, (err, wl)->
        wl.id.should.eql savedWalletId
        done()


  describe "findByAccount", ()->
    savedWalletId = undefined
    
    beforeEach (done)->
      GLOBAL.db.Wallet.create({user_id: 2, currency: "BTC"}).complete (err, wl)->
        savedWalletId = wl.id
        done()

    it "returns a wallet by the given account", (done)->
      GLOBAL.db.Wallet.findByAccount "wallet_#{savedWalletId}", (err, wl)->
        wl.id.should.eql savedWalletId
        done()
