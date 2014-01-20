Wallet = require "../models/wallet"
MarketStats = require "../models/market_stats"

module.exports = (app)->

  app.get "/", (req, res)->
    MarketStats.getStats (err, marketStats)->
      res.render "site/index",
        title: 'Home'
        user: req.user
        marketStats: marketStats
        currencies: Wallet.getCurrencyNames()

  app.get "/trade", (req, res)->
    res.redirect "/trade/BTC/LTC"

  app.get "/trade/:currency1/:currency2", (req, res)->
    currency1 = req.params.currency1
    currency2 = req.params.currency2
    currencies = Wallet.getCurrencies()
    return res.redirect "/"  if currencies.indexOf(currency1) is -1 or currencies.indexOf(currency2) is -1
    MarketStats.getStats (err, marketStats)->
      Wallet.findUserWalletByCurrency req.user.id, currency1, (err, wallet1)->
        Wallet.findUserWalletByCurrency req.user.id, currency2, (err, wallet2)->
          res.redirect "/funds"  if not wallet1 or not wallet2
          res.render "site/trade",
            title: "Trade #{currency1} to #{currency2}"
            user: req.user
            currency1: currency1
            currency2: currency2
            wallet1: wallet1
            wallet2: wallet2
            currencies: Wallet.getCurrencyNames()
            marketStats: marketStats

  app.get "/funds", (req, res)->
    Wallet.findUserWallets req.user.id, (err, wallets)->
      res.render "site/funds",
        title: 'Funds'
        user: req.user
        wallets: wallets
        currencies: Wallet.getCurrencyNames()

  app.get "/funds/:currency", (req, res)->
    Wallet.findUserWallets req.user.id, (err, wallets)->
      Wallet.findUserWalletByCurrency req.user.id, req.params.currency, (err, wallet)->
        console.error err  if err
        if wallet
          res.render "site/funds/wallet",
            title: 'Wallet overview'
            user: req.user
            wallet: wallet
            wallets: wallets
            currencies: Wallet.getCurrencyNames()
        else
          res.redirect "/"

  # Settings
  app.get "/settings", (req, res)->
    res.render "site/settings/settings",
      title: 'Settings'
      page: 'Settings'
      user: req.user

  app.get "/settings/preferences", (req, res)->
    res.render "site/settings/preferences",
      title: 'Preferences - Settings'
      page: 'Settings'
      user: req.user

  app.get "/settings/security", (req, res)->
    res.render "site/settings/security",
      title: 'Security - Settings'
      page: 'Settings'
      user: req.user

  # Static Pages
  app.get "/legal/terms", (req, res)->
    res.render "static/terms",
      title: 'Terms'

  app.get "/legal/privacy", (req, res)->
    res.render "static/privacy",
      title: 'Privacy'

  app.get "/legal/cookie", (req, res)->
    res.render "static/cookie",
      title: 'Cookie'

  app.get "/fees", (req, res)->
    res.render "static/fees",
      title: 'Fees'

  app.get "/company", (req, res)->
    res.render "static/company",
      title: 'Company'