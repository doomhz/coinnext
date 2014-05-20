Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
MarketHelper = require "../lib/market_helper"
JsonRenderer = require "../lib/json_renderer"
_ = require "underscore"

module.exports = (app)->

  app.post "/orders", (req, res)->
    return JsonRenderer.error "You need to be logged in to place an order.", res  if not req.user
    return JsonRenderer.error "Sorry, but you can not trade. Did you verify your account?", res  if not req.user.canTrade()
    data = req.body
    data.user_id = req.user.id
    data.status = "open"
    data.amount = parseFloat data.amount
    data.amount = MarketHelper.toBigint data.amount  if _.isNumber(data.amount) and not _.isNaN(data.amount) and _.isFinite(data.amount)
    data.unit_price = parseFloat data.unit_price
    data.unit_price = MarketHelper.toBigint data.unit_price  if _.isNumber(data.unit_price) and not _.isNaN(data.unit_price) and _.isFinite(data.unit_price)
    newOrder = Order.build data
    errors = newOrder.validate()
    return JsonRenderer.error errors, res  if errors
    newOrder.publish (err, order)->
      return JsonRenderer.error err, res  if err
      res.json JsonRenderer.order order

  app.get "/orders", (req, res)->
    if req.query.user_id?
      req.query.user_id = req.user.id  if req.user
      req.query.user_id = 0  if not req.user
    Order.findByOptions req.query, (err, orders)->
      return JsonRenderer.error "Sorry, could not get open orders...", res  if err
      res.json JsonRenderer.orders orders

  app.del "/orders/:id", (req, res)->
    return JsonRenderer.error "You need to be logged in to delete an order.", res  if not req.user
    Order.findByUserAndId req.params.id, req.user.id, (err, order)->
      return JsonRenderer.error "Sorry, could not delete orders...", res  if err or not order
      order.cancel (err)->
        console.error "Could not cancel order - #{err}"  if err
        return res.json JsonRenderer.order order  if err
        res.json {}
