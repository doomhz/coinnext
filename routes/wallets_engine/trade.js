(function() {
  var restify;

  restify = require("restify");

  module.exports = function(app) {
    return app.put("/complete_trade/:trade_id", function(req, res, next) {
      var tradeId;
      tradeId = req.params.trade_id;
      return res.send({
        id: tradeId,
        status: "complete"
      });
    });
  };

}).call(this);
