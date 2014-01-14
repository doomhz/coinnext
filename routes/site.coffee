Wallet = require "../models/wallet"

module.exports = (app)->

  app.get "/", (req, res)->
    res.render "site/index",
      title: 'Home'
      user: req.user

  app.get "/trade", (req, res)->
    res.redirect "/trade/BTC/LCT"

  app.get "/trade/:currency1/:currency2", (req, res)->
    currency1 = req.params.currency1
    currency2 = req.params.currency2
    currencies = Wallet.getCurrencies()
    res.redirect "/"  if currencies.indexOf(currency1) is -1 or currencies.indexOf(currency2) is -1
    Wallet.findUserWalletByCurrency req.user.id, currency1, (err, wallet1)->
      Wallet.findUserWalletByCurrency req.user.id, currency2, (err, wallet2)->
        res.redirect "/funds"  if not wallet1 or not wallet2
        res.render "site/trade",
          title: 'Trade #{currency1} to #{currency2}'
          user: req.user
          wallet1: wallet1
          wallet2: wallet2
          currencies: Wallet.getCurrencyNames()

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
      title: 'Preferencs - Settings'
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

  app.get "/fees", (req, res)->
    res.render "static/fees",
      title: 'Fees'

  app.get "/company", (req, res)->
    res.render "static/company",
      title: 'Company'