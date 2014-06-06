reCaptcha = require "recaptcha-async"
User = GLOBAL.db.User
UserToken = GLOBAL.db.UserToken
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
    oldStagingAuth = req.session.staging_auth
    oldCsrf = req.session.csrfSecret
    req.session.regenerate ()->
      req.session.staging_auth = oldStagingAuth
      req.session.csrfSecret = oldCsrf
      return res.redirect "/"  if req.accepts "html"
      res.json({})

  app.get "/send-password", (req, res)->
    if req.query.error
      errors = [req.query.error]
    success = req.query.success
    res.render "auth/send_password",
      title: "Send Password - Coinnext.com"
      errors: errors
      success: success
      recaptchaPublicKey: GLOBAL.appConfig().recaptcha.public_key

  app.post "/send-password", (req, res)->
    email = req.body.email
    return res.redirect "/send-password"  if not email
    dataIsLoaded = false
    recaptcha = new reCaptcha.reCaptcha()
    recaptcha.on "data", (captchaRes)->
      if not dataIsLoaded
        dataIsLoaded = true
        return res.redirect "/send-password?error=invalid-captcha"  if not captchaRes.is_valid
        User.findByEmail email, (err, user)->
          return res.redirect "/send-password?success=true"  if not user
          user.sendChangePasswordLink ()->
            return res.redirect "/send-password?success=true"
    recaptcha.checkAnswer GLOBAL.appConfig().recaptcha.private_key, req.connection.remoteAddress, req.body.recaptcha_challenge_field, req.body.recaptcha_response_field

  app.get "/change-password/:token", (req, res)->
    token = req.params.token
    req.logout()
    oldStagingAuth = req.session.staging_auth
    oldCsrf = req.session.csrfSecret
    req.session.regenerate ()->
      req.session.staging_auth = oldStagingAuth
      req.session.csrfSecret = oldCsrf
      UserToken.findByToken token, (err, userToken)->
        return res.redirect "/404"  if not userToken
        if req.query.error
          errors = [req.query.error]
        res.render "auth/change_password", {title: "Change Password - Coinnext.com", token: token, errors: errors}

  app.post "/change-password", (req, res)->
    token = req.body.token
    password = req.body.password
    UserToken.findByToken token, (err, userToken)->
      return res.redirect "/404"  if not userToken
      User.findByToken token, (err, user)->
        if not user
          res.writeHead(303, {"Location": "/change-password/#{token}?error=wrong-token"})
          res.end()
        user.changePassword password, (err, u)->
          console.error err  if err
          return JsonRenderer.error err, res  if err
          UserToken.invalidateByToken token
          res.writeHead(303, {"Location": "/login"})
          res.end()

  app.post "/set-new-password", (req, res)->
    password = req.body.password
    newPassword = req.body.new_password
    return JsonRenderer.error "Please auth.", res  if not req.user
    return JsonRenderer.error "The old password is incorrect.", res  if User.hashPassword(password) isnt req.user.password
    req.user.changePassword newPassword, (err, u)->
      console.error err  if err
      return JsonRenderer.error err, res  if err
      res.json
        message: "The password was successfully changed."

  app.get "/verify/:token", (req, res)->
    token = req.params.token
    req.logout()
    oldStagingAuth = req.session.staging_auth
    oldCsrf = req.session.csrfSecret
    req.session.regenerate ()->
      req.session.staging_auth = oldStagingAuth
      req.session.csrfSecret = oldCsrf
      UserToken.findByToken token, (err, userToken)->
        return res.redirect "/404"  if not userToken
        User.findByToken token, (err, user)->
          return res.redirect "/404"  if not user
          user.setEmailVerified (err, u)->
            res.render "auth/verify", {title: "Verify Account - Coinnext.com", user: u}
            UserToken.invalidateByToken token

  app.get "/resend", (req, res)->
    user = req.user
    return res.redirect "/404"  if not user or user.email_verified
    req.logout()
    oldStagingAuth = req.session.staging_auth
    oldCsrf = req.session.csrfSecret
    req.session.regenerate ()->
      req.session.staging_auth = oldStagingAuth
      req.session.csrfSecret = oldCsrf
      UserToken.findEmailConfirmationToken user.id, (err, userToken)->
        return res.redirect "/404"  if not userToken
        User.findByToken userToken.token, (err, user)->
          return res.redirect "/404"  if not user
          user.sendEmailVerificationLink ()->
            res.render "auth/resend_verify_link", {title: "Resend Verification Link - Coinnext.com", user: user}
            UserToken.invalidateByToken userToken.token

  app.post "/google_auth", (req, res)->
    return JsonRenderer.error null, res, 401, false  if not req.user
    res.json UserToken.generateGAuthData()

  app.put "/google_auth/:id?", (req, res)->
    return JsonRenderer.error null, res, 401, false  if not req.user
    return JsonRenderer.error "Invalid Google Authenticator code", res, 401  if not UserToken.isValidGAuthPassForKey req.body.gauth_pass, req.body.gauth_key
    UserToken.addGAuthTokenForUser req.body.gauth_key, req.user.id, (err, user)->
      res.json user

  app.del "/google_auth/:id?", (req, res)->
    return JsonRenderer.error null, res, 401, false  if not req.user
    UserToken.isValidGAuthPassForUser req.user.id, req.body.gauth_pass, (err, isValid)->
      return JsonRenderer.error "Invalid Google Authenticator code", res, 401  if not isValid
      UserToken.dropGAuthDataForUser req.user.id, ()->
        res.json JsonRenderer.user req.user


  login = (req, res, next)->
    passport.authenticate("local", (err, user, info)->
      return JsonRenderer.error err, res, 401  if err
      return JsonRenderer.error "Invalid credentials", res, 401  if not user
      req.logIn user, (err)->
        return JsonRenderer.error "Invalid credentials", res, 401  if err
        UserToken.findByUserAndType user.id, "google_auth", (err, googleToken)->
          if googleToken and not googleToken.isValidGAuthPass req.body.gauth_pass
            req.logout()
            return JsonRenderer.error "Invalid Google Authenticator code", res, 401
          oldSessionPassport = req.session.passport
          oldStagingAuth = req.session.staging_auth
          oldCsrf = req.session.csrfSecret
          req.session.regenerate ()->
            req.session.passport = oldSessionPassport
            req.session.staging_auth = oldStagingAuth
            req.session.csrfSecret = oldCsrf
            res.json JsonRenderer.user req.user
            AuthStats.log {ip: req.ip, user: req.user}, req.user.email_auth_enabled and not req.user.recenltySignedUp()
    )(req, res, next)
