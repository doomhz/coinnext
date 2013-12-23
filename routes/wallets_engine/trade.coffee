restify = require "restify"

module.exports = (app)->

  app.put "/complete_order/:order_id", (req, res, next)->
    orderId = req.params.order_id
    res.send
      id:     orderId
      status: "complete"
