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
    @setupConfirmations(options)
    @setupWallet(options)

  createClient: (options)->

  setupConfirmations: (options)->
    @confirmations = options.confirmations or @confirmations

  setupWallet: (options)->
    @account = options.wallet.account
    @address = options.wallet.address
    @passphrase = options.wallet.passphrase

  generateAddress: (account, callback)->
    @client.getNewAddress account, callback

  sendToAddress: (address, amount, callback)->
    amount = @convert @currency, @initialCurrency, amount
    @submitPassphrase (err)=>
      return callback err  if err
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

exports = module.exports = CryptoWallet