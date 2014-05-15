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
      newUser.sendEmailVerificationLink()
      Wallet.findOrCreateUserWalletByCurrency newUser.id, "BTC"
      res.json JsonRenderer.user newUser

  app.get "/user/:id?", (req, res)->
    return JsonRenderer.error null, res, 401, false  if not req.user
    res.json JsonRenderer.user req.user

  app.put "/user/:id?", (req, res)->
    return JsonRenderer.error null, res, 401, false  if not req.user
    req.user.updateSettings req.body, (err, user)->
      return JsonRenderer.error err, res  if err
      res.json JsonRenderer.user user
