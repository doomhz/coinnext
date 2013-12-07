module.exports = (app)->

  app.get "/", (req, res)->
    res.render "site/index",
      user: req.user

  app.get "/signup", (req, res)->
    res.render "site/signup"
