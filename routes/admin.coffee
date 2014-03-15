#Transaction = GLOBAL.db.Transaction
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
      page: "stats"
      btcBankAddress: GLOBAL.wallets["BTC"].address
      ppcBankAddress: GLOBAL.wallets["PPC"].address
      ltcBankAddress: GLOBAL.wallets["LTC"].address
      _str: _str
      _: _

  app.get "/administratie/banksaldo", (req, res)->
    res.json
      btcBankBalance: 0
      ppcBankBalance: 0
      ltcBankBalance: 0

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