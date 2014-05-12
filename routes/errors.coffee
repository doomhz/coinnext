module.exports = (app)->
  
  app.use (req, res)->
    console.error "404 - [#{req.method}][#{req.ip}] #{req.originalUrl}"
    res.statusCode = 404
    if req.accepts "html"
      return res.render "errors/404",
        title: "Page not found"
    if req.accepts "json"
      return res.send
        error: "Not found"
    res.type("txt").send("Not found")
