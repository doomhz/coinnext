User = require '../models/user'
JsonRenderer = require '../lib/json_renderer'

module.exports = (app)->
  
  app.post "/user", (req, res)->
    user = new User
      email: req.body.email
      password:  User.hashPassword req.body.password
    user.save (err)->
      return JsonRenderer.error err, res  if err
      user.sendEmailVerificationLink()
      res.json JsonRenderer.user user

  app.post "/login", (req, res, next)->
    login req, res, next

  app.put "/login", (req, res, next)->
    login req, res, next

  app.get "/user/:id?", (req, res)->
    return JsonRenderer.error null, res  if not req.user
    res.json JsonRenderer.user req.user

  app.get "/logout", (req, res)->
    req.logout()
    if req.accepts "html"
      res.redirect "/"
    else
      res.json({})

  app.get "/generate_gauth", (req, res)->
    return JsonRenderer.error null, res  if not req.user
    req.user.generateGAuthData ()->
      res.json JsonRenderer.user req.user

  app.post "/user_event", (req, res, next)->
    userId = req.body.user_id
    eventType = req.body.type
    data = req.body.data
    if GLOBAL.usersSocket
      try
        for sId, socket of GLOBAL.usersSocket.sockets
          socket.emit eventType, data  if socket.user_id is userId
        res.json({})
      catch e
        console.error "Could not emit to socket namespace /users #{userId}: #{e}"
        JsonRenderer.error "Could not emit to socket namespace /users #{userId}", res

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


  GLOBAL.usersSocket = GLOBAL.io.of("/users").on "connection", (socket)->
    socket.on "listen", (data)->
      socket.user_id = data.id
