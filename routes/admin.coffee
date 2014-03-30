Wallet = GLOBAL.db.Wallet
User = GLOBAL.db.User
Transaction = GLOBAL.db.Transaction
Payment = GLOBAL.db.Payment
AuthStats = GLOBAL.db.AuthStats
MarketHelper = require "../lib/market_helper"
JsonRenderer = require "../lib/json_renderer"
jsonBeautifier = require "../lib/json_beautifier"
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
      adminUser: req.user
      _str: _str
      _: _
      currencies: MarketHelper.getCurrencyTypes()

  app.get "/administratie/users", (req, res)->
    count = req.query.count or 20
    from = if req.query.from? then parseInt(req.query.from) else 0
    query =
      order: [
        ["updated_at", "DESC"]
      ]
      limit: count
      offset: from
    User.findAndCountAll(query).complete (err, result = {rows: [], count: 0})->
      res.render "admin/users",
        title: "Users - Admin - Satoshibet"
        page: "users"
        adminUser: req.user
        _str: _str
        _: _
        currencies: MarketHelper.getCurrencyTypes()
        users: result.rows
        totalUsers: result.count
        from: from
        count: count

  app.get "/administratie/user/:id", (req, res)->
    User.findById req.params.id, (err, user)->
      Wallet.findAll({where: {user_id: req.params.id}}).complete (err, wallets)->
        query =
          where:
            user_id: req.params.id
          order: [
            ["created_at", "DESC"]
          ]
          limit: 20
        AuthStats.findAll(query).complete (err, authStats)->
          res.render "admin/user",
            title: "User #{user.email} - #{user.id} - Admin - Satoshibet"
            page: "users"
            adminUser: req.user
            _str: _str
            _: _
            currencies: MarketHelper.getCurrencyTypes()
            user: user
            wallets: wallets
            authStats: authStats

  app.get "/administratie/wallet/:id", (req, res)->
    Wallet.findById req.params.id, (err, wallet)->
      res.render "admin/wallet",
        title: "Wallet #{wallet.id} - Admin - Satoshibet"
        page: "wallets"
        adminUser: req.user
        _str: _str
        _: _
        currencies: MarketHelper.getCurrencyTypes()
        wallet: wallet

  app.get "/administratie/wallets", (req, res)->
    count = req.query.count or 20
    from = if req.query.from? then parseInt(req.query.from) else 0
    currency = if req.query.currency? then req.query.currency else "BTC"
    query =
      where:
        currency: currency
      order: [
        ["balance", "DESC"]
      ]
      limit: count
      offset: from
    Wallet.findAndCountAll(query).complete (err, result = {rows: [], count: 0})->
      res.render "admin/wallets",
        title: "Wallets - Admin - Satoshibet"
        page: "wallets"
        adminUser: req.user
        _str: _str
        _: _
        currencies: MarketHelper.getCurrencyTypes()
        wallets: result.rows
        totalWallets: result.count
        from: from
        count: count
        currency: currency

  app.get "/administratie/transactions", (req, res)->
    userId = req.query.user_id or ""
    count = req.query.count or 20
    from = if req.query.from? then parseInt(req.query.from) else 0
    query =
      order: [
        ["created_at", "DESC"]
      ]
      limit: count
      offset: from
    if userId
      query.where =
        user_id: userId
    Transaction.findAndCountAll(query).complete (err, result = {rows: [], count: 0})->
      res.render "admin/transactions",
        title: "Transactions - Admin - Satoshibet"
        page: "transactions"
        adminUser: req.user
        _str: _str
        _: _
        currencies: MarketHelper.getCurrencyTypes()
        transactions: result.rows
        totalTransactions: result.count
        from: from
        count: count
        jsonBeautifier: jsonBeautifier

  app.get "/administratie/payments", (req, res)->
    userId = req.query.user_id or ""
    count = req.query.count or 20
    from = if req.query.from? then parseInt(req.query.from) else 0
    query =
      order: [
        ["created_at", "DESC"]
      ]
      limit: count
      offset: from
    if userId
      query.where =
        user_id: userId
    Payment.findAndCountAll(query).complete (err, result = {rows: [], count: 0})->
      res.render "admin/payments",
        title: "Payments - Admin - Satoshibet"
        page: "payments"
        adminUser: req.user
        _str: _str
        _: _
        currencies: MarketHelper.getCurrencyTypes()
        payments: result.rows
        totalPayments: result.count
        from: from
        count: count
        jsonBeautifier: jsonBeautifier

  app.put "/administratie/pay/:id", (req, res)->
    id = req.params.id
    GLOBAL.walletsClient.send "process_payment", [id], (err, res2, body)=>
      return JsonRenderer.error err, res  if err
      if body and body.paymentId?
        Payment.findById id, (err, payment)->
          return JsonRenderer.error err, res  if err
          res.json JsonRenderer.payment payment
      else
        return JsonRenderer.error "Could not process payment - #{JSON.stringify(body)}", res

  app.post "/administratie/clear_pending_payments", (req, res)->
    Payment.destroy({status: "pending"}).complete (err, payment)->
      res.json {}

  app.get "/administratie/banksaldo/:currency", (req, res)->
    currency = req.params.currency
    GLOBAL.walletsClient.send "wallet_balance", [currency], (err, res2, body)=>
      return JsonRenderer.error err, res  if err
      if body and body.balance?
        res.json body
      else
        res.json
          currency: currency
          balance: "wallet error"

  app.post "/administratie/wallet_info", (req, res)->
    currency = req.body.currency
    GLOBAL.walletsClient.send "wallet_info", [currency], (err, res2, body)=>
      return JsonRenderer.error err, res  if err
      if body and body.info?
        res.json body
      else
        res.json
          currency: currency
          info: "wallet error"

  app.post "/administratie/search_user", (req, res)->
    term = req.body.term
    renderUser = (err, user = {})->
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
        if user.gauth_key and not user.isValidGAuthPass req.body.gauth_pass
          req.logout()
          return res.redirect "/administratie/login"
        res.redirect "/administratie"
    )(req, res, next)