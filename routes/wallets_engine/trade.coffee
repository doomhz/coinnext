restify = require "restify"

module.exports = (app)->

  app.put "/complete_trade/:trade_id", (req, res, next)->
    tradeId = req.params.trade_id
    res.send
      id:     tradeId
      status: "complete"
