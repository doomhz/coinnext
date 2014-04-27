require "./../../helpers/spec_helper"

describe "Transaction", ->
  transaction     = undefined
  wallet          = GLOBAL.db.Wallet.build {user_id: 1}
  trTime          = Date.now() / 1000
  transactionData =
    amount: 1
    txid: "unique_tx_id"
    confirmations: 6
    time: trTime
    account:  "account"
    fee:      0.0001
    address:  "address"
    category: "send"

  beforeEach (done)->
    transaction = GLOBAL.db.Transaction.build()
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      done()
  

  describe "addFromWallet", ()->
    describe "when the given transaction does not exist", ()->
      it "creates one", (done)->
        GLOBAL.db.Transaction.addFromWallet transactionData, "BTC", wallet, (err, tr)->
          expectedData = {
            id: 1, currency: "BTC", account: "account", fee: 10000, amount: 100000000, address: "address", category: "send", txid: "unique_tx_id", confirmations: 6
          }
          tr.values.should.have.properties expectedData
          done()

    describe "when the given transaction already exists", ()->
      it "updates it", (done)->
        GLOBAL.db.Transaction.addFromWallet transactionData, "BTC", wallet, (err, trOld)->
          newTransactionData = transactionData
          newTransactionData.confirmations = 10
          GLOBAL.db.Transaction.addFromWallet newTransactionData, "BTC", wallet, (err, tr)->
            expectedData = {
              id: 1, currency: "BTC", account: "account", fee: 10000, amount: 100000000, address: "address", category: "send", txid: "unique_tx_id", confirmations: 10
            }
            tr.values.should.have.properties expectedData
            trOld.id.should.eql tr.id
            done()
