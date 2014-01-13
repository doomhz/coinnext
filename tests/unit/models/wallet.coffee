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

  beforeEach ->
    wallet = new Wallet
    GLOBAL.walletsClient =
      send: (action, data, callback)->
        if action is "create_account"
          return callback null, null, {address: "address_#{data[0]}_#{data[1]}"}
        return callback "Unknown action"
  
  afterEach (done)->
    GLOBAL.walletsClient = undefined
    Wallet.remove ()->
      done()


  describe "account", ()->
    it "returns a virtual wallet account", ()->
      wallet.account.should.eql "wallet_#{wallet._id}"


  describe "generateAddress", ()->
    it "sets a new wallet address", (done)->
      wallet.generateAddress (err, wl)->
        wl.address.should.eql "address_#{wallet.account}_#{wallet.currency}"
        done()


  describe "addBalance", ()->
    it "adds the balance to the wallet", (done)->
      wallet.balance = 0
      wallet.save (err, wl)->
        wl.addBalance 3, (err, syncedWallet)->
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


  describe "getCurrencies", ()->
    it "returns the available currencies list", ()->
      Wallet.getCurrencies().toString().should.equal CURRENCIES.toString()


  describe "findUserWalletByCurrency", ()->
    savedWalletId = undefined
    
    beforeEach (done)->
      Wallet.create {user_id: "user_id", currency: "BTC"}, (err, wl)->
        savedWalletId = wl.id
        Wallet.create {user_id: "user_id", currency: "LTC"}, ()->
          Wallet.create {user_id: "user_id2", currency: "LTC"}, ()->
            done()

    describe "when there is a wallet for the given user with the given currency", ()->
      it "returns the first wallet with the given user id and currency", (done)->
        Wallet.findUserWalletByCurrency "user_id", "BTC", (err, wl)->
          wl.id.should.eql savedWalletId
          done()


  describe "findUserWallets", ()->
    beforeEach (done)->
      Wallet.create {user_id: "user_id", currency: "BTC", created: Date.now() - 1000}, (err, wl)->
        Wallet.create {user_id: "user_id", currency: "LTC", created: Date.now()}, ()->
          Wallet.create {user_id: "user_id2", currency: "LTC"}, ()->
            done()

    it "returns the user wallets", (done)->
      Wallet.findUserWallets "user_id", (err, wallets)->
        wallets.length.should.eql 2
        done()

    it "orders the wallets desc by created", (done)->
      Wallet.findUserWallets "user_id", (err, wallets)->
        [wallets[0].currency, wallets[1].currency].toString().should.eql ["LTC", "BTC"].toString()
        done()


  describe "findUserWallet", ()->
    savedWalletId = undefined
    
    beforeEach (done)->
      Wallet.create {user_id: "user_id", currency: "BTC"}, ()->
        Wallet.create {user_id: "user_id", currency: "LTC"}, (err, wl)->
          savedWalletId = wl.id
          Wallet.create {user_id: "user_id2", currency: "LTC"}, ()->
            done()

    it "returns the user wallet by the given user id and wallet id", (done)->
      Wallet.findUserWallet "user_id", savedWalletId, (err, wl)->
        wl.id.should.eql savedWalletId
        done()


  describe "findByAccount", ()->
    savedWalletId = undefined
    
    beforeEach (done)->
      Wallet.create {user_id: "user_id", currency: "BTC"}, (err, wl)->
        savedWalletId = wl.id
        done()

    it "returns a wallet by the given account", (done)->
      Wallet.findByAccount "wallet_#{savedWalletId}", (err, wl)->
        wl.id.should.eql savedWalletId
        done()
