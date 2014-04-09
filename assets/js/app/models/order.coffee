window.App or= {}

class App.OrderModel extends Backbone.Model

  urlRoot: "/orders"

  calculateFirstAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return _.str.satoshiRound App.math.select(@get("amount")).divide(@get("unit_price")).add(-@get("result_amount")).done()  if @get("action") is "buy"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("sold_amount"))  if @get("action") is "sell"
      if @get("type") is "limit"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("result_amount"))  if @get("action") is "buy"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("sold_amount"))  if @get("action") is "sell"
    if @get("status") is "completed"
      return _.str.satoshiRound @get("result_amount")  if @get("action") is "buy"
      return _.str.satoshiRound @get("sold_amount")  if @get("action") is "sell"
    if @get("type") is "market"
      return _.str.satoshiRound App.math.divide @get("amount"), @get("unit_price")  if @get("action") is "buy"
      return _.str.satoshiRound @get("amount")  if @get("action") is "sell"
    return _.str.satoshiRound @get("amount")  if @get("type") is "limit"

  calculateSecondAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("sold_amount"))  if @get("action") is "buy"
        return _.str.satoshiRound App.math.multiply(App.math.add(@get("amount"), -@get("sold_amount")), @get("unit_price"))  if @get("action") is "sell"
      if @get("type") is "limit"
        return _.str.satoshiRound App.math.multiply(App.math.add(@get("amount"), -@get("result_amount")), @get("unit_price"))  if @get("action") is "buy"
        return _.str.satoshiRound App.math.multiply(App.math.add(@get("amount"), -@get("sold_amount")), @get("unit_price"))  if @get("action") is "sell"
    if @get("status") is "completed"
      return _.str.satoshiRound @get("sold_amount")  if @get("action") is "buy"
      return _.str.satoshiRound @get("result_amount")  if @get("action") is "sell"
    if @get("type") is "market"
      return _.str.satoshiRound @get("amount")  if @get("action") is "buy"
      return _.str.satoshiRound App.math.multiply(@get("amount"), @get("unit_price"))  if @get("action") is "sell"
    return _.str.satoshiRound App.math.multiply(@get("amount"), @get("unit_price"))  if @get("type") is "limit"

  getCreatedDate: ()->
    new Date(@get('created_at')).format('dd.mm.yy hh:ss')