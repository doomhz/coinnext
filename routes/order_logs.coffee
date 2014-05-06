OrderLog = GLOBAL.db.OrderLog
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.get "/order_logs", (req, res)->
    req.query.user_id = req.user.id  if req.query.user_id?
    OrderLog.findActiveByOptions req.query, (err, orderLogs)->
      return JsonRenderer.error "Sorry, could not get closed orders...", res  if err
      res.json JsonRenderer.orderLogs orderLogs
