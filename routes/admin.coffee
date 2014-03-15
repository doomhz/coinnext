#Transaction = GLOBAL.db.Transaction
Wallet = GLOBAL.db.Wallet
User = GLOBAL.db.User
JsonRenderer = require "../lib/json_renderer"
_ = require "underscore"
_str = require "../lib/underscore_string"

module.exports = (app)->

  app.get "/administratie/login", (req, res, next)->
    res.render "admin/login"

  app.post "/administratie/login", (req, res, next)->
    login req, res, next

  app.get "/administratie/logout", (req, res, next)->
    req.logout()
    return res.redirect "/administratie"

  app.get "/administratie*", (req, res, next)->
    res.redirect "/administratie/login"  if not req.user
    next()

  app.get "/administratie", (req, res)->
    res.render "admin/stats",
      title: "Stats - Admin - Satoshibet"
      _str: _str
      _: _
      currencies: Wallet.getCurrencies()

  app.get "/administratie/banksaldo/:currency", (req, res)->
    currency = req.params.currency
    if GLOBAL.wallets[currency]
      GLOBAL.wallets[currency].getBankBalance (err, balance)->
        console.log err  if err
        res.json
          balance: balance or "wallet inaccessible"
          currency: currency
    else
      res.json
        balance: "wallet inaccessible"
        currency: currency

  app.post "/administratie/wallet_info", (req, res)->
    currency = req.body.currency
    if GLOBAL.wallets[currency]
      GLOBAL.wallets[currency].getInfo (err, info)->
        console.log err  if err
        res.json
          info: info or "wallet inaccessible"
          currency: currency
          address: GLOBAL.appConfig().wallets[currency.toLowerCase()].wallet.address
    else
      res.json
        info: "wallet inaccessible"
        currency: currency

  app.post "/administratie/search_user", (req, res)->
    term = req.body.term
    renderUser = (err, user)->
      res.json user
    return User.findById term, renderUser  if _.isNumber parseInt(term)
    return User.findByEmail term, renderUser  if term.indexOf("@") > -1
    Wallet.findByAddress term, (err, wallet)->
      return User.findById wallet.user_id, renderUser  if wallet
      res.json
        error: "Could not find user by #{term}"


  login = (req, res, next)->
    passport.authenticate("local", (err, user, info)->
      return res.redirect "/administratie/login"  if err
      return res.redirect "/administratie/login"  if not user
      req.logIn user, (err)->
        return res.redirect "/administratie/login"  if err
        if user.gauth_data and not user.isValidGAuthPass req.body.gauth_pass
          req.logout()
          return res.redirect "/administratie/login"
        res.redirect "/administratie"
    )(req, res, next)