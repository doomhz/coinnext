speakeasy = require "speakeasy"

module.exports = (app)->

  app.get "/", (req, res)->
    res.render "site/index",
      title: 'Home'
      user: req.user

  app.get "/signup", (req, res)->
    res.render "site/signup"

  app.get "/login", (req, res)->
    res.render "site/login"

  app.get "/trade", (req, res)->
    res.render "site/trade",
      title: 'Trade'
      user: req.user

  app.get "/finances", (req, res)->
    res.render "site/finances",
      title: 'Finances'
      user: req.user

  app.get "/settings", (req, res)->
    res.render "site/settings",
      title: 'Settings'
      user: req.user