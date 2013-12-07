module.exports = (app)->

  app.get "/", (req, res)->
    res.render "site/index"

  app.get "/signup", (req, res)->
    res.render "site/signup"
