window.App or= {}

class App.OrderModel extends Backbone.Model

  urlRoot: "/orders"

  calculateFirstAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return App.math.select(@get("amount")).divide(@get("unit_price")).add(-@get("result_amount")).done()  if @get("action") is "buy"
        return App.math.add @get("amount"), -@get("sold_amount")  if @get("action") is "sell"
      if @get("type") is "limit"
        return App.math.add @get("amount"), -@get("result_amount")  if @get("action") is "buy"
        return App.math.add @get("amount"), -@get("sold_amount")  if @get("action") is "sell"
    if @get("status") is "completed"
      return _.str.roundTo @get("result_amount"), 8  if @get("action") is "buy"
      return _.str.roundTo @get("sold_amount"), 8  if @get("action") is "sell"
    if @get("type") is "market"
      return App.math.divide @get("amount"), @get("unit_price")  if @get("action") is "buy"
      return _.str.roundTo @get("amount"), 8  if @get("action") is "sell"
    return _.str.roundTo @get("amount"), 8  if @get("type") is "limit"

  calculateSecondAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return App.math.add @get("amount"), -@get("sold_amount")  if @get("action") is "buy"
        return App.math.multiply App.math.add(@get("amount"), -@get("sold_amount")), @get("unit_price")  if @get("action") is "sell"
      if @get("type") is "limit"
        return App.math.multiply App.math.add(@get("amount"), -@get("result_amount")), @get("unit_price")  if @get("action") is "buy"
        return App.math.multiply App.math.add(@get("amount"), -@get("sold_amount")), @get("unit_price")  if @get("action") is "sell"
    if @get("status") is "completed"
      return _.str.roundTo @get("sold_amount"), 8  if @get("action") is "buy"
      return _.str.roundTo @get("result_amount"), 8  if @get("action") is "sell"
    if @get("type") is "market"
      return _.str.roundTo @get("amount"), 8  if @get("action") is "buy"
      return App.math.multiply @get("amount"), @get("unit_price")  if @get("action") is "sell"
    return App.math.multiply @get("amount"), @get("unit_price")  if @get("type") is "limit"

  getCreatedDate: ()->
    new Date(@get('created_at')).format('dd.mm.yy hh:ss')