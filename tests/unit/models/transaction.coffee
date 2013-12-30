require "./../../helpers/spec_helper"

describe "Transaction", ->
  transaction     = undefined
  wallet          = new Wallet {user_id: "user_id"}
  trTime          = Date.now() / 1000
  transactionData =
    amount: 1
    txid: "unique_tx_id"
    confirmations: 6
    time: trTime
    details: [{
      account:  "account"
      fee:      0.0001
      address:  "address"
      category: "send"
    }]

  beforeEach ->
    transaction = new Transaction
  
  afterEach (done)->
    Transaction.remove ()->
      done()


  describe "addFromWallet", ()->
    describe "when the given transaction does not exist", ()->
      it "creates one", (done)->
        Transaction.addFromWallet transactionData, "BTC", wallet, (err, tr)->
          expectedData = "user_id,#{wallet.id},BTC,account,0.0001,address,1,send,unique_tx_id,6,#{new Date(trTime * 1000)}"
          [tr.user_id, tr.wallet_id, tr.currency, tr.account, tr.fee, tr.address, tr.amount, tr.category, tr.txid, tr.confirmations, tr.created].toString().should.eql expectedData.toString()
          done()

    describe "when the given transaction already exists", ()->
      it "updates it", (done)->
        Transaction.addFromWallet transactionData, "BTC", wallet, (err, trOld)->
          newTransactionData = transactionData
          newTransactionData.confirmations = 10
          Transaction.addFromWallet newTransactionData, "BTC", wallet, (err, tr)->
            expectedData = "user_id,#{wallet.id},BTC,account,0.0001,address,1,send,unique_tx_id,10,#{new Date(trTime * 1000)}"
            [tr.user_id, tr.wallet_id, tr.currency, tr.account, tr.fee, tr.address, tr.amount, tr.category, tr.txid, tr.confirmations, tr.created].toString().should.eql expectedData.toString()
            trOld.id.should.eql tr.id
            done()
