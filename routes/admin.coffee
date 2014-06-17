Wallet = GLOBAL.db.Wallet
User = GLOBAL.db.User
Transaction = GLOBAL.db.Transaction
Payment = GLOBAL.db.Payment
Order = GLOBAL.db.Order
AuthStats = GLOBAL.db.AuthStats
UserToken = GLOBAL.db.UserToken
MarketStats = GLOBAL.db.MarketStats
MarketHelper = require "../lib/market_helper"
JsonRenderer = require "../lib/json_renderer"
jsonBeautifier = require "../lib/json_beautifier"
_ = require "underscore"

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
    MarketStats.findRemovedCurrencies (err, removedCurrencies)->
      currencies = MarketHelper.getCurrencyTypes().filter (curr)->
        removedCurrencies.indexOf(curr) is -1
      res.render "admin/stats",
        title: "Stats - Admin - CoinNext"
        page: "stats"
        adminUser: req.user
        currencies: currencies

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
        title: "Users - Admin - CoinNext"
        page: "users"
        adminUser: req.user
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
          UserToken.findByUserAndType user.id, "google_auth", (err, userToken)->
            res.render "admin/user",
              title: "User #{user.email} - #{user.id} - Admin - CoinNext"
              page: "users"
              adminUser: req.user
              currencies: MarketHelper.getCurrencyTypes()
              user: user
              userToken: userToken
              wallets: wallets
              authStats: authStats

  app.get "/administratie/wallet/:id", (req, res)->
    Wallet.findById req.params.id, (err, wallet)->
      openOptions =
        sell_currency: wallet.currency
        status: "open"
        user_id: wallet.user_id
        currency1: wallet.currency
        include_logs: true
      closedOptions =
        sell_currency: wallet.currency
        status: "completed"
        user_id: wallet.user_id
        currency1: wallet.currency
        include_logs: true
      Order.findByOptions openOptions, (err, openOrders)->
        Order.findByOptions closedOptions, (err, closedOrders)->
          res.render "admin/wallet",
            title: "Wallet #{wallet.id} - Admin - CoinNext"
            page: "wallets"
            adminUser: req.user
            currencies: MarketHelper.getCurrencyTypes()
            wallet: wallet
            openOrders: openOrders
            closedOrders: closedOrders

  app.get "/administratie/wallets", (req, res)->
    count = req.query.count or 20
    from = if req.query.from? then parseInt(req.query.from) else 0
    currency = if req.query.currency? then req.query.currency else "BTC"
    query =
      where:
        currency: MarketHelper.getCurrency currency
      order: [
        ["balance", "DESC"]
      ]
      limit: count
      offset: from
    Wallet.findAndCountAll(query).complete (err, result = {rows: [], count: 0})->
      res.render "admin/wallets",
        title: "Wallets - Admin - CoinNext"
        page: "wallets"
        adminUser: req.user
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
      include: [
        {model: GLOBAL.db.User, attributes: ["username", "email"]}
      ]
    if userId
      query.where =
        user_id: userId
    Transaction.findAndCountAll(query).complete (err, result = {rows: [], count: 0})->
      res.render "admin/transactions",
        title: "Transactions - Admin - CoinNext"
        page: "transactions"
        adminUser: req.user
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
      include: [
        {model: GLOBAL.db.PaymentLog}
      ]
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
        title: "Payments - Admin - CoinNext"
        page: "payments"
        adminUser: req.user
        currencies: MarketHelper.getCurrencyTypes()
        payments: result.rows
        totalPayments: result.count
        from: from
        count: count
        jsonBeautifier: jsonBeautifier

  app.put "/administratie/pay/:id", (req, res)->
    id = req.params.id
    GLOBAL.coreAPIClient.send "process_payment", [id], (err, res2, body)=>
      return JsonRenderer.error err, res  if err
      if body and body.paymentId?
        Payment.findById id, (err, payment)->
          return JsonRenderer.error "Could not process payment - #{JSON.stringify(body)}", res  if not payment.isProcessed()
          return JsonRenderer.error err, res  if err
          res.json JsonRenderer.payment payment
      else
        return JsonRenderer.error "Could not process payment - #{JSON.stringify(body)}", res

  app.del "/administratie/payment/:id", (req, res)->
    id = req.params.id
    GLOBAL.coreAPIClient.send "cancel_payment", [id], (err, res2, body)=>
      return JsonRenderer.error err, res  if err
      if body and body.paymentId?
        res.json
          id: id
          status: "removed"
      else
        return JsonRenderer.error "Could not cancel payment - #{JSON.stringify(body)}", res

  app.get "/administratie/banksaldo/:currency", (req, res)->
    currency = req.params.currency
    GLOBAL.coreAPIClient.send "wallet_balance", [currency], (err, res2, body)=>
      return JsonRenderer.error err, res  if err
      if body and body.balance?
        res.json body
      else
        res.json
          currency: currency
          balance: "wallet error"

  app.post "/administratie/wallet_info", (req, res)->
    currency = req.body.currency
    GLOBAL.coreAPIClient.send "wallet_info", [currency], (err, res2, body)=>
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
    return User.findById term, renderUser  if not _.isNaN parseInt(term)
    return User.findByEmail term, renderUser  if term.indexOf("@") > -1
    User.findByUsername term, (err, user)->
      return renderUser err, user  if user
      Wallet.findByAddress term, (err, wallet)->
        return User.findById wallet.user_id, renderUser  if wallet
        res.json
          error: "Could not find user by #{term}"

  app.get "/administratie/markets", (req, res)->
    MarketStats.getStats (err, markets)->
      res.render "admin/markets",
        title: "Markets - Admin - CoinNext"
        page: "markets"
        adminUser: req.user
        currencies: MarketHelper.getCurrencyTypes()
        markets: markets

  app.put "/administratie/markets/:id", (req, res)->
    MarketStats.setMarketStatus req.params.id, req.body.status, (err, market)->
      console.error err  if err
      res.json market

  app.post "/administratie/resend_user_verification_email/:id", (req, res)->
    User.findById req.params.id, (err, user)->
      if user
        user.sendEmailVerificationLink (err)->
          if err
            console.error err
            res.json
              error: "Could not send email #{err}"
          else
            res.json
              user_id: user.id
      else
        res.json
          error: "Could not find user #{userId}"


  login = (req, res, next)->
    passport.authenticate("local", (err, user, info)->
      return res.redirect "/administratie/login"  if err
      return res.redirect "/administratie/login"  if not user
      req.logIn user, (err)->
        return res.redirect "/administratie/login"  if err
        if process.env.NODE_ENV is "production"
          if user.gauth_key and not user.isValidGAuthPass req.body.gauth_pass
            req.logout()
            return res.redirect "/administratie/login"
        res.redirect "/administratie"
    )(req, res, next)