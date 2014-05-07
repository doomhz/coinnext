window.App or= {}

class App.OrderLogModel extends Backbone.Model

  urlRoot: "/order_logs"

  calculateFirstAmount: ()->
    return _.str.satoshiRound @get("result_amount")  if @get("action") is "buy"
    return _.str.satoshiRound @get("matched_amount")  if @get("action") is "sell"

  calculateSecondAmount: ()->
    return _.str.satoshiRound @get("result_amount")  if @get("action") is "sell"
    return _.str.satoshiRound App.math.multiply @get("matched_amount"), @get("unit_price")  if @get("action") is "buy"

  getTime: ()->
    new Date(@get('time')).format('dd.mm.yy H:MM')
