User = GLOBAL.db.User
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.get "/signup", (req, res)->
    res.render "auth/signup"

  app.get "/login", (req, res)->
    res.render "auth/login"

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
