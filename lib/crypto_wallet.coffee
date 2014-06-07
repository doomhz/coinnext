coind = require "node-coind"

class CryptoWallet

  confirmations: null

  address: null
  
  account: null

  passphrase: null

  passphraseTimeout: 5

  currency: null

  initialCurrency: null

  currencyName: null

  convertionRates: {}

  constructor: (options)->
    options = @loadOptions() if not options
    @createClient(options)
    @setupCurrency(options)
    @setupConfirmations(options)
    @setupWallet(options)

  createClient: (options)->
    options.client.sslCa = @loadCertificate options.client.sslCa  if options.client.sslCa
    @client = new coind.Client options.client

  setupCurrency: (options)->
    @currency = options.currency
    @initialCurrency = options.initialCurrency or @currency
    @currencyName = options.currencyName

  setupConfirmations: (options)->
    @confirmations = options.confirmations or @confirmations

  setupWallet: (options)->
    @account = options.wallet.account
    @address = options.wallet.address
    @passphrase = options.wallet.passphrase

  generateAddress: (account, callback)->
    @submitPassphrase (err)=>
      console.error err  if err
      @client.getNewAddress account, callback

  sendToAddress: (address, amount, callback)->
    amount = @convert @currency, @initialCurrency, amount
    @submitPassphrase (err)=>
      console.error err  if err
      @client.sendToAddress address, amount, callback

  submitPassphrase: (callback)->
    return callback()  if not @passphrase
    @client.walletPassphrase @passphrase, @passphraseTimeout, callback

  convert: (fromCurrency, toCurrency, amount)->
    if @convertionRates?["#{fromCurrency}_#{toCurrency}"]
      return parseFloat(parseFloat(amount * @convertionRates["#{fromCurrency}_#{toCurrency}"]).toFixed(8))
    parseFloat(parseFloat(amount).toFixed(8))

  getInfo: (callback)->
    @client.getInfo callback

  getBlockCount: (callback)->
    @client.getBlockCount callback

  getBlockHash: (blockIndex, callback)->
    @client.getBlockHash blockIndex, callback

  getBlock: (blockHash, callback)->
    @client.getBlock blockHash, callback

  getBestBlockHash: (callback)->
    @getBlockCount (err, blockCount)=>
      @getBlockHash blockCount - 1, callback

  getBestBlock: (callback)->
    @getBestBlockHash (err, blockHash)=>
      @getBlock blockHash, callback

  getTransactions: (account = "*", count = 10, from = 0, callback)->
    @client.listTransactions account, count, from, callback

  getTransaction: (txId, callback)->
    @client.getTransaction txId, callback

  getBalance: (account, callback)->
    @client.getBalance account, (err, balance)=>
      balance = @convert @initialCurrency, @currency, balance
      callback(err, balance) if callback

  getBankBalance: (callback)->
    @getBalance "*", callback

  isBalanceConfirmed: (existentConfirmations)->
    existentConfirmations >= @confirmations

  loadOptions: ()->
    GLOBAL.appConfig().wallets[@initialCurrency.toLowerCase()]

  loadCertificate: (path)->
    require("fs").readFileSync("#{__dirname}/../#{path}")

exports = module.exports = CryptoWallet