window.App or= {}

class App.OrderModel extends Backbone.Model

  urlRoot: "/orders"

  calculateFirstAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return parseFloat(@get("amount") / @get("unit_price") - @get("result_amount"))  if @get("action") is "buy"
        return parseFloat(@get("amount") - @get("sold_amount"))  if @get("action") is "sell"
      if @get("type") is "limit"
        return parseFloat(@get("amount") - @get("result_amount"))  if @get("action") is "buy"
        return parseFloat(@get("amount") - @get("sold_amount"))  if @get("action") is "sell"
    if @get("status") is "completed"
      return parseFloat @get("result_amount")  if @get("action") is "buy"
      return parseFloat @get("sold_amount")  if @get("action") is "sell"
    if @get("type") is "market"
      return parseFloat @get("amount") / @get("unit_price")  if @get("action") is "buy"
      return parseFloat @get("amount")  if @get("action") is "sell"
    return parseFloat @get("amount")  if @get("type") is "limit"

  calculateSecondAmount: ()->
    if @get("status") is "partiallyCompleted"
      if @get("type") is "market"
        return parseFloat(@get("amount") - @get("sold_amount"))  if @get("action") is "buy"
        return parseFloat((@get("amount") - @get("sold_amount")) * @get("unit_price"))  if @get("action") is "sell"
      if @get("type") is "limit"
        return parseFloat((@get("amount") - @get("result_amount")) * @get("unit_price"))  if @get("action") is "buy"
        return parseFloat((@get("amount") - @get("sold_amount")) * @get("unit_price"))  if @get("action") is "sell"
    if @get("status") is "completed"
      return parseFloat @get("sold_amount")  if @get("action") is "buy"
      return parseFloat @get("result_amount")  if @get("action") is "sell"
    if @get("type") is "market"
      return parseFloat @get("amount")  if @get("action") is "buy"
      return parseFloat @get("amount") * @get("unit_price")  if @get("action") is "sell"
    return parseFloat @get("amount") * @get("unit_price")  if @get("type") is "limit"

  getCreatedDate: ()->
    new Date(@get('created')).format('dd.mm.yy hh:ss')