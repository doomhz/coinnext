speakeasy = require "speakeasy"

module.exports = (app)->

  app.get "/", (req, res)->
    res.render "site/index",
      user: req.user

  app.get "/signup", (req, res)->
    res.render "site/signup"

  app.get "/settings", (req, res)->
    res.render "site/settings",
      user: req.user