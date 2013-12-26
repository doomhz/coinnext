Wallet = require "../models/wallet"

module.exports = (app)->

  app.get "/", (req, res)->
    res.render "site/index",
      title: 'Home'
      user: req.user

  app.get "/trade", (req, res)->
    res.render "site/trade",
      title: 'Trade'
      user: req.user

  app.get "/funds", (req, res)->
    res.render "site/funds",
      title: 'Funds'
      user: req.user
      currencies: Wallet.getCurrencies()

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