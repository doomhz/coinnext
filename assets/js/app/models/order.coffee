window.App or= {}

class App.OrderModel extends Backbone.Model

  urlRoot: "/orders"

  calculateFirstAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return _.str.satoshiRound App.math.select(@get("amount")).divide(@get("unit_price")).add(-@get("result_amount")).done()  if @get("action") is "buy"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("matched_amount"))  if @get("action") is "sell"
      if @get("type") is "limit"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("result_amount"))  if @get("action") is "buy"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("matched_amount"))  if @get("action") is "sell"
    if @get("status") is "completed"
      return _.str.satoshiRound @get("result_amount")  if @get("action") is "buy"
      return _.str.satoshiRound @get("matched_amount")  if @get("action") is "sell"
    if @get("type") is "market"
      return _.str.satoshiRound App.math.divide @get("amount"), @get("unit_price")  if @get("action") is "buy"
      return _.str.satoshiRound @get("amount")  if @get("action") is "sell"
    return _.str.satoshiRound @get("amount")  if @get("type") is "limit"

  calculateSecondAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return _.str.satoshiRound App.math.add(@get("amount"), -@get("matched_amount"))  if @get("action") is "buy"
        return _.str.satoshiRound App.math.multiply(App.math.add(@get("amount"), -@get("matched_amount")), @get("unit_price"))  if @get("action") is "sell"
      if @get("type") is "limit"
        return _.str.satoshiRound App.math.multiply(App.math.add(@get("amount"), -@get("result_amount")), @get("unit_price"))  if @get("action") is "buy"
        return _.str.satoshiRound App.math.multiply(App.math.add(@get("amount"), -@get("matched_amount")), @get("unit_price"))  if @get("action") is "sell"
    if @get("status") is "completed"
      return _.str.satoshiRound @get("matched_amount")  if @get("action") is "buy"
      return _.str.satoshiRound @get("result_amount")  if @get("action") is "sell"
    if @get("type") is "market"
      return _.str.satoshiRound @get("amount")  if @get("action") is "buy"
      return _.str.satoshiRound App.math.multiply(@get("amount"), @get("unit_price"))  if @get("action") is "sell"
    return _.str.satoshiRound App.math.multiply(@get("amount"), @get("unit_price"))  if @get("type") is "limit"

  calculateFirstNoFeeAmount: ()->
    return _.str.satoshiRound App.math.add(@get("amount"), -@get("matched_amount"))  if @get("status") is "partiallyCompleted"
    return _.str.satoshiRound @get("amount")

  calculateSecondNoFeeAmount: ()->
    if @get("status") is "partiallyCompleted"
      return _.str.satoshiRound App.math.multiply(App.math.add(@get("amount"), -@get("matched_amount")), @get("unit_price"))
    if @get("status") is "completed"
      return _.str.satoshiRound @get("amount")  if @get("action") is "buy"
    return _.str.satoshiRound App.math.multiply(@get("amount"), @get("unit_price"))

  getCreatedDate: ()->
    new Date(@get('created_at')).format('dd.mm.yy H:MM')

  mergeWithOrder: (orderToMerge)->
    attributes = orderToMerge.toJSON()
    return @attributes = attributes  if _.isEmpty @attributes
    @set
      amount: App.math.add @attributes.amount, attributes.amount
      matched_amount: App.math.add @attributes.matched_amount, attributes.matched_amount
      result_amount: App.math.add @attributes.result_amount, attributes.result_amount
