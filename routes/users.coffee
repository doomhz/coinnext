User = require '../models/user'
JsonRenderer = require '../lib/json_renderer'

module.exports = (app)->
  
  app.post "/user", (req, res)->
    user = new User
      email : req.body.email
      password : req.body.password
    user.save (err)->
      if err
        console.error "Could not create user", err
        res.statusCode = 409
        res.json {"error" : "User cannot be created"}
      else
        res.json JsonRenderer.user user

  app.post "/login", passport.authenticate("local"), (req, res)->
    res.json JsonRenderer.user req.user

  app.put "/login", passport.authenticate("local"), (req, res)->
    res.json JsonRenderer.user req.user

  app.get "/user/:id?", (req, res)->
    if not req.user
      res.statusCode = 409
      return {}
    res.json JsonRenderer.user req.user

  app.get "/logout", (req, res)->
    req.logout()
    res.json({})