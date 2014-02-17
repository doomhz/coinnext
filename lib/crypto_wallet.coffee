class CryptoWallet

  configPath: "config.json"

  confirmations: 0

  transactionFee: 0.0001

  currency: null

  constructor: (options)->
    @configPath = options.configPath if options and options.configPath
    options = @loadOptionsFromFile() if not options
    @createClient(options)
    @setupConfirmations(options)
    @setupTransactionFee(options)

  createClient: (options)->

  setupConfirmations: (options)->
    @confirmations = options.confirmations or @confirmations

  setupTransactionFee: (options)->
    @transactionFee = options.transaction_fee or @transactionFee
    @client.setTxFee @transactionFee

  generateAddress: (account, callback)->
    @client.getNewAddress account, callback

  sendToAddress: (address, amount, callback)->
    amount = @parseAmount amount
    @client.sendToAddress address, amount, callback

  parseAmount: (amount)->
    parseFloat(parseFloat(amount).toFixed(9))

  getInfo: (callback)->
    @client.getInfo callback

  getTransactions: (account = "*", count = 10, from = 0, callback)->
    @client.listTransactions account, count, from, callback

  getTransaction: (txId, callback)->
    @client.getTransaction txId, callback

  getBankBalance: (callback)->
    @client.cmd "getbalance", (err, balance)=>
      callback(err, balance) if callback

  isBalanceConfirmed: (existentConfirmations)->
    existentConfirmations >= @confirmations

  loadOptionsFromFile: ()->
    options = GLOBAL.appConfig()
    if not options
      fs = require "fs"
      environment = process.env.NODE_ENV or "development"
      options = JSON.parse(fs.readFileSync("#{process.cwd()}/#{@configPath}", "utf8"))[environment]
    options.wallets[@currency.toLowerCase()]

exports = module.exports = CryptoWallet