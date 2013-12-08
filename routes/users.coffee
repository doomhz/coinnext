User = require '../models/user'
JsonRenderer = require '../lib/json_renderer'

module.exports = (app)->
  
  app.post "/user", (req, res)->
    user = new User
      email: req.body.email
      password:  User.hashPassword req.body.password
    user.save (err)->
      if err
        console.error "Could not create user", err
        res.statusCode = 409
        res.json {"error" : "User cannot be created"}
      else
        res.json JsonRenderer.user user

  app.post "/login", (req, res, next)->
    login req, res, next

  app.put "/login", (req, res, next)->
    login req, res, next

  app.get "/user/:id?", (req, res)->
    if not req.user
      res.statusCode = 409
      return {}
    res.json JsonRenderer.user req.user

  app.get "/logout", (req, res)->
    req.logout()
    res.json({})

  app.get "/generate_gauth", (req, res)->
    if not req.user
      res.statusCode = 409
      return {}
    req.user.generateGAuthData ()->
      res.json JsonRenderer.user req.user

  login = (req, res, next)->
    passport.authenticate("local", (err, user, info)->
      if err
        res.statusCode = 401
        return res.json {error: err}
      if not user
        res.statusCode = 401
        return res.json {error: "Invalid credentials"}
      req.logIn user, (err)->
        if err
          res.statusCode = 401
          return res.json {error: "Invalid credentials"}
        if user.gauth_data and not user.isValidGAuthPass req.body.gauth_pass
          req.logout()
          res.statusCode = 401
          return res.json {error: "Invalid Google Authenticator code"}
        res.json JsonRenderer.user req.user
    )(req, res, next)
