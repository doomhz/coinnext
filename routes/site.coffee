Wallet = require "../models/wallet"
MarketStats = GLOBAL.db.MarketStats
TradeStats = require "../models/trade_stats"
Order = require "../models/order"
_str = require "../lib/underscore_string"

module.exports = (app)->

  app.get "/", (req, res)->
    MarketStats.getStats (err, marketStats)->
      res.render "site/index",
        title: 'Home'
        user: req.user
        marketStats: marketStats
        currencies: Wallet.getCurrencyNames()

  app.get "/trade", (req, res)->
    res.redirect "/trade/LTC/BTC"

  app.get "/trade/:currency1/:currency2", (req, res)->
    currency1 = req.params.currency1
    currency2 = req.params.currency2
    currencies = Wallet.getCurrencies()
    return res.redirect "/"  if currencies.indexOf(currency1) is -1 or currencies.indexOf(currency2) is -1
    MarketStats.getStats (err, marketStats)->
      if req.user
        Wallet.findUserWalletByCurrency req.user.id, currency1, (err, wallet1)->
          if not wallet1
            wallet1 = new Wallet
              currency: currency1
          Wallet.findUserWalletByCurrency req.user.id, currency2, (err, wallet2)->
            if not wallet2
              wallet2 = new Wallet
                currency: currency2
            res.render "site/trade",
              title: "Trade #{currency1} to #{currency2}"
              user: req.user
              currency1: currency1
              currency2: currency2
              wallet1: wallet1
              wallet2: wallet2
              currencies: Wallet.getCurrencyNames()
              marketStats: marketStats
              _str: _str
      else
        res.render "site/trade",
          title: "Trade #{currency1} to #{currency2}"
          currency1: currency1
          currency2: currency2
          wallet1: new Wallet
            currency: currency1
          wallet2: new Wallet
            currency: currency2
          currencies: Wallet.getCurrencyNames()
          marketStats: marketStats
          _str: _str

  app.get "/funds", (req, res)->
    return res.redirect "/login"  if not req.user
    Wallet.findUserWallets req.user.id, (err, wallets)->
      res.render "site/funds",
        title: 'Funds'
        user: req.user
        wallets: wallets
        currencies: Wallet.getCurrencyNames()
        _str: _str

  app.get "/funds/:currency", (req, res)->
    return res.redirect "/login"  if not req.user
    Wallet.findUserWallets req.user.id, (err, wallets)->
      Wallet.findUserWalletByCurrency req.user.id, req.params.currency, (err, wallet)->
        console.error err  if err
        return res.redirect "/"  if not wallet
        res.render "site/funds/wallet",
          title: 'Wallet overview'
          user: req.user
          wallet: wallet
          wallets: wallets
          currencies: Wallet.getCurrencyNames()
          _str: _str

  app.get "/market_stats", (req, res)->
    MarketStats.getStats (err, marketStats)->
      res.json marketStats

  app.get "/trade_stats/:market_type", (req, res)->
    TradeStats.getLastStats req.params.market_type, (err, tradeStats = [])->
      res.json tradeStats


  # Settings
  app.get "/settings", (req, res)->
    return res.redirect "/login"  if not req.user
    res.render "site/settings/settings",
      title: 'Settings'
      page: 'Settings'
      user: req.user

  app.get "/settings/preferences", (req, res)->
    return res.redirect "/login"  if not req.user
    res.render "site/settings/preferences",
      title: 'Preferences - Settings'
      page: 'Settings'
      user: req.user

  app.get "/settings/security", (req, res)->
    return res.redirect "/login"  if not req.user
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

  app.get "/security", (req, res)->
    res.render "static/security",
      title: 'Security'

  app.get "/whitehat", (req, res)->
    res.render "static/whitehat",
      title: 'White Hat'