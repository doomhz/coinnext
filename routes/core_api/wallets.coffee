WalletHealth = GLOBAL.db.WalletHealth
MarketHelper = require "../../lib/market_helper"
restify = require "restify"

module.exports = (app)->

  app.post "/create_account/:account/:currency", (req, res, next)->
    account   = req.params.account
    currency = req.params.currency
    return return next(new restify.ConflictError "Wrong Currency.")  if not GLOBAL.wallets[currency]
    GLOBAL.wallets[currency].generateAddress account, (err, address)->
      console.error err  if err
      return next(new restify.ConflictError "Could not generate address.")  if err
      res.send
        account: account
        address: address

  app.get "/wallet_balance/:currency", (req, res, next)->
    currency = req.params.currency
    return return next(new restify.ConflictError "Wallet down or does not exist.")  if not GLOBAL.wallets[currency]
    GLOBAL.wallets[currency].getBankBalance (err, balance)->
      console.error err  if err
      return next(new restify.ConflictError "Wallet inaccessible.")  if err
      res.send
        currency: currency
        balance: balance

  app.get "/wallet_info/:currency", (req, res, next)->
    currency = req.params.currency
    return return next(new restify.ConflictError "Wallet down or does not exist.")  if not GLOBAL.wallets[currency]
    GLOBAL.wallets[currency].getInfo (err, info)->
      console.error err  if err
      return next(new restify.ConflictError "Wallet inaccessible.")  if err
      res.send
        currency: currency
        info: info
        address: GLOBAL.appConfig().wallets[currency.toLowerCase()].wallet.address

  app.get "/wallet_health", (req, res, next)->
    console.log "/wallet_health"
    walletsInfo = []
    for currency, wallet of GLOBAL.wallets
      wallet.getInfo (err, info)->
        if err
          console.error err
          walletInfo = 
            status: "error"
        else
          walletInfo = 
            currency: currency
            block: info.blocks
            connections: info.connections
            balance: MarketHelper.toBigint info.balance
          lastBlock = wallet.getBestBlock()
          lastUpdated = lastBlock.time
          wallet.last_updated = new Date(lastUpdated)  # TODO review
          wallet.status = MarketHelper.getWalletLastUpdatedStatus(lastUpdated)
        walletsInfo.push walletInfo
    WalletHealth.bulkCreate(walletsInfo).complete (err, result)->
      res.send
        message: "Wallet health check performed on #{new Date()}"
        result: result