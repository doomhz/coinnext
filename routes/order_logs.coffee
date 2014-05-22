OrderLog = GLOBAL.db.OrderLog
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.get "/order_logs", (req, res)->
    if req.query.user_id?
      req.query.user_id = req.user.id  if req.user
      req.query.user_id = 0  if not req.user
    OrderLog.findActiveByOptions req.query, (err, orderLogs)->
      return JsonRenderer.error "Sorry, could not get closed orders...", res  if err
      res.json JsonRenderer.orderLogs orderLogs
