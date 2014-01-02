peercoin = require("node-peercoin")

class PpcWallet

  configPath: "config.json"

  address: null
  
  account: null

  confirmations: 1

  transactionFee: 0.0001

  balanceConfirmations: 0

  currency: "PPC"

  convertionRates:
    PPC_mPPC: 1000
    mPPC_PPC: 0.001
    PPC_PPC: 1
    mPPC_mPPC: 1

  constructor: (options)->
    @configPath = options.configPath if options and options.configPath
    options = @loadOptionsFromFile() if not options
    @createClient(options)
    @setupWallet(options)
    @setupConfirmations(options)
    @setupTransactionFee(options)
    @setCurrency(options.currency)

  createClient: (options)->
    @client = new peercoin.Client options.client

  setupWallet: (options)->
    @account = options.wallet.account
    @address = options.wallet.address

  setupConfirmations: (options)->
    @confirmations = options.confirmations or @confirmations
    @balanceConfirmations = options.balance_confirmations or @balanceConfirmations

  setupTransactionFee: (options)->
    @transactionFee = options.transaction_fee or @transactionFee
    @client.setTxFee @transactionFee

  setCurrency: (currency)->
    @currency = currency or @currency

  generateAddress: (account, callback)->
    @client.getNewAddress account, callback

  getBalance: (account, callback)->
    @client.getBalance account, @balanceConfirmations, (err, balance)=>
      balance = @convert "PPC", @currency, balance
      callback(err, balance) if callback

  chargeAccount: (account, amount, callback)->
    amount = @convert @currency, "PPC", amount
    fromAccount = if amount > 0 then @account else account
    toAccount = if amount > 0 then account else @account
    amount = if amount < 0 then amount * -1 else amount
    @client.move fromAccount, toAccount, amount, callback

  sendToAddress: (address, fromAccount, amount, callback)->
    amount = @convert @currency, "PPC", amount
    @client.sendFrom fromAccount, address, amount, @confirmations, callback

  convert: (fromCurrency, toCurrency, amount)->
    parseFloat(parseFloat(amount * @convertionRates["#{fromCurrency}_#{toCurrency}"]).toFixed(9))

  getInfo: (callback)->
    @client.getInfo callback

  getAccounts: (callback)->
    @client.listAccounts callback

  getTransactions: (account = "*", count = 10, from = 0, callback)->
    @client.listTransactions account, count, from, callback

  getTransaction: (txId, callback)->
    @client.getTransaction txId, callback

  getBankBalance: (callback)->
    @getBalance @account, callback

  loadOptionsFromFile: ()->
    options = GLOBAL.appConfig()
    if not options
      fs = require "fs"
      environment = process.env.NODE_ENV or "development"
      options = JSON.parse(fs.readFileSync("#{process.cwd()}/#{@configPath}", "utf8"))[environment]
    options.wallets.ppc

exports = module.exports = PpcWallet