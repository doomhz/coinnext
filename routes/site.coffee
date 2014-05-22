Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
TradeStats = GLOBAL.db.TradeStats
AuthStats = GLOBAL.db.AuthStats
UserToken = GLOBAL.db.UserToken
JsonRenderer = require "../lib/json_renderer"
MarketHelper = require "../lib/market_helper"
_str = require "../lib/underscore_string"

module.exports = (app)->

  app.get "/", (req, res)->
    MarketStats.getStats (err, marketStats)->
      res.render "site/index",
        title: if req.user then 'Home - Coinnext' else 'Coinnext - Cryptocurrency Exchange'
        page: "home"
        user: req.user
        marketStats: JsonRenderer.marketStats marketStats
        currencies: MarketHelper.getCurrencyNames()
        _str: _str

  app.get "/trade", (req, res)->
    res.redirect "/trade/LTC/BTC"

  app.get "/trade/:currency1/:currency2", (req, res)->
    currency1 = req.params.currency1
    currency2 = req.params.currency2
    return res.redirect "/"  if not MarketHelper.isValidCurrency(currency1) or not MarketHelper.isValidCurrency(currency2)
    MarketStats.getStats (err, marketStats)->
      if req.user
        Wallet.findUserWalletByCurrency req.user.id, currency1, (err, wallet1)->
          if not wallet1
            wallet1 = Wallet.build
              currency: currency1
          Wallet.findUserWalletByCurrency req.user.id, currency2, (err, wallet2)->
            if not wallet2
              wallet2 = Wallet.build
                currency: currency2
            res.render "site/trade",
              title: "Trade #{MarketHelper.getCurrencyName(currency1)} to #{MarketHelper.getCurrencyName(currency2)} - #{currency1}/#{currency2} - Coinnext"
              page: "trade"
              user: req.user
              currency1: currency1
              currency2: currency2
              wallet1: wallet1
              wallet2: wallet2
              currencies: MarketHelper.getCurrencyNames()
              marketStats: JsonRenderer.marketStats marketStats
              _str: _str
      else
        res.render "site/trade",
          title: "Trade #{MarketHelper.getCurrencyName(currency1)} to #{MarketHelper.getCurrencyName(currency2)} - #{currency1}/#{currency2} - Coinnext - Cryptocurrency Exchange"
          page: "trade"
          currency1: currency1
          currency2: currency2
          wallet1: Wallet.build
            currency: currency1
          wallet2: Wallet.build
            currency: currency2
          currencies: MarketHelper.getCurrencyNames()
          marketStats: JsonRenderer.marketStats marketStats
          _str: _str

  app.get "/funds", (req, res)->
    return res.redirect "/login"  if not req.user
    Wallet.findUserWallets req.user.id, (err, wallets)->
      res.render "site/funds",
        title: 'Funds - Coinnext'
        page: "funds"
        user: req.user
        wallets: wallets
        currencies: MarketHelper.getCurrencyNames()
        _str: _str

  app.get "/funds/:currency", (req, res)->
    return res.redirect "/login"  if not req.user
    Wallet.findUserWallets req.user.id, (err, wallets)->
      Wallet.findUserWalletByCurrency req.user.id, req.params.currency, (err, wallet)->
        console.error err  if err
        return res.redirect "/"  if not wallet
        res.render "site/funds/wallet",
          title: "#{req.params.currency} - Funds - Coinnext"
          page: "funds"
          user: req.user
          wallet: wallet
          wallets: wallets
          currencies: MarketHelper.getCurrencyNames()
          _str: _str

  app.get "/market_stats", (req, res)->
    MarketStats.getStats (err, marketStats)->
      res.json JsonRenderer.marketStats marketStats

  app.get "/trade_stats/:market_type", (req, res)->
    TradeStats.getLastStats req.params.market_type, (err, tradeStats = [])->
      res.json JsonRenderer.tradeStats tradeStats


  # Settings
  #app.get "/settings", (req, res)->
  #  return res.redirect "/login"  if not req.user
  #  res.render "site/settings/settings",
  #    title: 'Settings'
  #    page: 'settings'
  #    user: req.user

  app.get "/settings/preferences", (req, res)->
    return res.redirect "/login"  if not req.user
    res.render "site/settings/preferences",
      title: 'Preferences - Settings - Coinnext'
      page: 'settings'
      user: req.user

  app.get "/settings/security", (req, res)->
    return res.redirect "/login"  if not req.user
    AuthStats.findByUser req.user.id, (err, authStats)->
      UserToken.findByUserAndType req.user.id, "google_auth", (err, googleToken)->
        res.render "site/settings/security",
          title: 'Security - Settings - Coinnext'
          page: 'settings'
          user: req.user
          authStats: authStats
          googleToken: googleToken

  # Static Pages
  app.get "/legal/terms", (req, res)->
    res.render "static/terms",
      title: 'Terms - Coinnext'
      user: req.user

  app.get "/legal/privacy", (req, res)->
    res.render "static/privacy",
      title: 'Privacy - Coinnext'
      user: req.user

  app.get "/legal/cookie", (req, res)->
    res.render "static/cookie",
      title: 'Cookie - Coinnext'
      user: req.user

  app.get "/fees", (req, res)->
    res.render "static/fees",
      title: 'Fees - Coinnext'
      user: req.user

  app.get "/about", (req, res)->
    res.render "static/about",
      title: 'About - Coinnext'
      user: req.user

  app.get "/security", (req, res)->
    res.render "static/security",
      title: 'Security - Coinnext'
      user: req.user

  app.get "/api", (req, res)->
    res.render "static/api",
      title: 'API - Coinnext'
      user: req.user