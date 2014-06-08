WalletHealth = GLOBAL.db.WalletHealth
MarketHelper = require "../../lib/market_helper"
restify = require "restify"

module.exports = (app)->

  app.post "/create_account/:account/:currency", (req, res, next)->
    account   = req.params.account
    currency = req.params.currency
    return next(new restify.ConflictError "Wrong Currency.")  if not GLOBAL.wallets[currency]
    GLOBAL.wallets[currency].generateAddress account, (err, address)->
      console.error err  if err
      return next(new restify.ConflictError "Could not generate address.")  if err
      res.send
        account: account
        address: address

  app.get "/wallet_balance/:currency", (req, res, next)->
    currency = req.params.currency
    return next(new restify.ConflictError "Wallet down or does not exist.")  if not GLOBAL.wallets[currency]
    GLOBAL.wallets[currency].getBankBalance (err, balance)->
      console.error err  if err
      return next(new restify.ConflictError "Wallet inaccessible.")  if err
      res.send
        currency: currency
        balance: balance

  app.get "/wallet_info/:currency", (req, res, next)->
    currency = req.params.currency
    return next(new restify.ConflictError "Wallet down or does not exist.")  if not GLOBAL.wallets[currency]
    GLOBAL.wallets[currency].getInfo (err, info)->
      console.error err  if err
      return next(new restify.ConflictError "Wallet inaccessible.")  if err
      res.send
        currency: currency
        info: info
        address: GLOBAL.appConfig().wallets[currency.toLowerCase()].wallet.address

  app.get "/wallet_health/:currency", (req, res, next)->
    currency = req.params.currency
    return next(new restify.ConflictError "Wallet down or does not exist.")  if not GLOBAL.wallets[currency]
    wallet = GLOBAL.wallets[currency]
    walletInfo = {}
    wallet.getInfo (err, info)->
      if err or not info
        console.error err
        walletInfo.status = "error"
        walletInfo.currency = currency
        walletInfo.blocks = null
        walletInfo.connections = null
        walletInfo.balance = null
        walletInfo.lastUpdated = null
        return WalletHealth.updateFromWalletInfo walletInfo, (err, result)->
          return next(new restify.ConflictError "Can't update wallet health from walletInfo")  if err
          res.send
            message: "Wallet health check performed on #{new Date()}"
            result: result
      
      walletInfo.currency = currency
      walletInfo.blocks = info.blocks
      walletInfo.connections = info.connections
      walletInfo.balance = MarketHelper.toBigint info.balance

      wallet.getBestBlock (err, lastBlock)->
        lastUpdated = if err or not lastBlock then NaN else lastBlock.time * 1000
        walletInfo.last_updated = new Date(lastUpdated)
        walletInfo.status = MarketHelper.getWalletLastUpdatedStatus walletInfo.last_updated

        WalletHealth.updateFromWalletInfo walletInfo, (err, result)->
          return next(new restify.ConflictError "Can't update wallet health from walletInfo")  if err
          res.send
            message: "Wallet health check performed on #{new Date()}"
            result: result