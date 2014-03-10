User = GLOBAL.db.User
Wallet = GLOBAL.db.Wallet
JsonRenderer = require '../lib/json_renderer'

module.exports = (app)->
  
  app.post "/user", (req, res)->
    data =
      email: req.body.email
      password: req.body.password
    User.createNewUser data, (err, newUser)->
      return JsonRenderer.error err, res  if err
      newUser.generateToken ()->
        newUser.sendEmailVerificationLink()
        Wallet.findOrCreateUserWalletByCurrency newUser.id, "BTC"
      res.json JsonRenderer.user newUser

  app.post "/login", (req, res, next)->
    login req, res, next

  app.put "/login", (req, res, next)->
    login req, res, next

  app.get "/user/:id?", (req, res)->
    return JsonRenderer.error null, res  if not req.user
    res.json JsonRenderer.user req.user

  app.get "/logout", (req, res)->
    req.logout()
    return res.redirect "/"  if req.accepts "html"
    res.json({})

  app.get "/generate_gauth", (req, res)->
    return JsonRenderer.error null, res  if not req.user
    req.user.generateGAuthData ()->
      res.json JsonRenderer.user req.user

  login = (req, res, next)->
    passport.authenticate("local", (err, user, info)->
      return JsonRenderer.error err, res, 401  if err
      return JsonRenderer.error "Invalid credentials", res, 401  if not user
      req.logIn user, (err)->
        return JsonRenderer.error "Invalid credentials", res, 401  if err
        if user.gauth_data and not user.isValidGAuthPass req.body.gauth_pass
          req.logout()
          return JsonRenderer.error "Invalid Google Authenticator code", res, 401
        res.json JsonRenderer.user req.user
    )(req, res, next)
