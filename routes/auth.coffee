User = GLOBAL.db.User
AuthStats = GLOBAL.db.AuthStats
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.get "/signup", (req, res)->
    res.render "auth/signup"

  app.get "/login", (req, res)->
    res.render "auth/login"

  app.post "/login", (req, res, next)->
    login req, res, next

  app.put "/login", (req, res, next)->
    login req, res, next

  app.get "/logout", (req, res)->
    req.logout()
    return res.redirect "/"  if req.accepts "html"
    res.json({})

  app.get "/send-password", (req, res)->
    if req.query.error
      errors = [req.query.error]
    success = req.query.success
    res.render "auth/send_password", {title: "Send Password - Coinnext.com", errors: errors, success: success}

  app.post "/send-password", (req, res)->
    email = req.body.email
    if not email
      res.writeHead(303, {"Location": "/send-password"})
      return res.end()
    User.findByEmail email, (err, user)->
      if not user
        res.writeHead(303, {"Location": "/send-password?error=wrong-user"})
        res.end()
      user.generateToken ()->
        user.sendPasswordLink ()->
          res.writeHead(303, {"Location": "/send-password?success=true"})
          res.end()

  app.get "/change-password/:token", (req, res)->
    token = req.params.token
    if req.query.error
      errors = [req.query.error]
    res.render "auth/change_password", {title: "Change Password - Coinnext.com", token: token, errors: errors}

  app.post "/change-password", (req, res)->
    token = req.body.token
    password = req.body.password
    User.findByToken token, (err, user)->
      if not user
        res.writeHead(303, {"Location": "/change-password/#{token}?error=wrong-token"})
        res.end()
      user.changePassword password, (err, u)->
        console.error err  if err
        res.writeHead(303, {"Location": "/login"})
        res.end()

  app.post "/set-new-password", (req, res)->
    password = req.body.password
    newPassword = req.body.new_password
    return JsonRenderer.error "Please auth.", res  if not req.user
    return JsonRenderer.error "The old password is incorrect.", res  if User.hashPassword(password) isnt req.user.password
    req.user.changePassword newPassword, (err, u)->
      console.error err  if err
      res.json
        message: "The password was successfully changed."

  app.get "/verify/:token", (req, res)->
    token = req.params.token
    User.findByToken token, (err, user)->
      return res.render "auth/verify", {title: "Verify Account - Coinnext.com"}  if not user
      user.setEmailVerified (err, u)->
        res.render "auth/verify", {title: "Verify Account - Coinnext.com", user: u}

  app.post "/google_auth", (req, res)->
    return JsonRenderer.error null, res  if not req.user
    res.json req.user.generateGAuthData()

  app.put "/google_auth/:id?", (req, res)->
    return JsonRenderer.error null, res  if not req.user
    return JsonRenderer.error "Invalid Google Authenticator code", res, 401  if not User.isValidGAuthPassForKey req.body.gauth_pass, req.body.gauth_key
    req.user.setGAuthData req.body.gauth_key, (err, user)->
      res.json user

  app.del "/google_auth/:id?", (req, res)->
    return JsonRenderer.error null, res  if not req.user
    return JsonRenderer.error "Invalid Google Authenticator code", res, 401  if not req.user.isValidGAuthPass req.body.gauth_pass
    req.user.dropGAuthData ()->
      res.json JsonRenderer.user req.user


  login = (req, res, next)->
    passport.authenticate("local", (err, user, info)->
      return JsonRenderer.error err, res, 401  if err
      return JsonRenderer.error "Invalid credentials", res, 401  if not user
      req.logIn user, (err)->
        return JsonRenderer.error "Invalid credentials", res, 401  if err
        if user.gauth_key and not user.isValidGAuthPass req.body.gauth_pass
          req.logout()
          return JsonRenderer.error "Invalid Google Authenticator code", res, 401
        res.json JsonRenderer.user req.user
        AuthStats.log {ip: req.ip, user: req.user}, req.user.email_auth_enabled
    )(req, res, next)
