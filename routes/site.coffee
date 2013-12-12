speakeasy = require "speakeasy"

module.exports = (app)->

  app.get "/", (req, res)->
    res.render "site/index",
      user: req.user

  app.get "/signup", (req, res)->
    res.render "site/signup"

  app.get "/login", (req, res)->
    res.render "site/login"

  app.get "/trade", (req, res)->
    res.render "site/trade"

  app.get "/settings", (req, res)->
    res.render "site/settings",
      user: req.user