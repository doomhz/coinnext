(function() {
  var JsonRenderer, OrderLog;

  OrderLog = GLOBAL.db.OrderLog;

  JsonRenderer = require("../lib/json_renderer");

  module.exports = function(app) {
    return app.get("/order_logs", function(req, res) {
      if (req.query.user_id != null) {
        req.query.user_id = req.user.id;
      }
      return OrderLog.findActiveByOptions(req.query, function(err, orderLogs) {
        if (err) {
          return JsonRenderer.error("Sorry, could not get closed orders...", res);
        }
        return res.json(JsonRenderer.orderLogs(orderLogs));
      });
    });
  };

}).call(this);
