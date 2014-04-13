request = require "request"
Order = GLOBAL.db.Order
Wallet = GLOBAL.db.Wallet
MarketStats = GLOBAL.db.MarketStats
JsonRenderer = require "./json_renderer"
MarketHelper = require "./market_helper"
ClientSocket = require "./client_socket"
orderSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "orders"
usersSocket = new ClientSocket
  host: GLOBAL.appConfig().app_host
  path: "users"
math = require("mathjs")
  number: "bignumber"
  decimals: 8

TradeHelper =

  submitOrder: (order, callback = ()->)->
    orderData =
      order_id: order.id
      type: order.type
      action: order.action
      buy_currency: order.buy_currency
      sell_currency: order.sell_currency
      amount: order.getDataValue "amount"
      unit_price: order.getDataValue "unit_price"
    uri = "#{GLOBAL.appConfig().engine_api_host}/order/#{order.id}"
    options =
      uri: uri
      method: "POST"
      json: orderData
    @sendEngineData uri, options, callback

  cancelOrder: (order, callback = ()->)->
    uri = "#{GLOBAL.appConfig().engine_api_host}/order/#{order.id}"
    options =
      uri: uri
      method: "DELETE"
    @sendEngineData uri, options, callback

  sendEngineData: (uri, options, callback)->
    try
      request options, (err, response, body)->
        if err or response.statusCode isnt 200
          err = "#{response.statusCode} - Could not send order data to #{uri} - #{JSON.stringify(options.json)} - #{JSON.stringify(err)} - #{JSON.stringify(body)}"
          console.log err
          return callback err
        return callback()
    catch e
      console.error e
      callback "Bad response #{e}"

  pushOrderUpdate: (data)->
    orderSocket.send data

  pushUserUpdate: (data)->
    usersSocket.send data

  updateMatchedOrder: (orderToMatch, matchData, transaction, callback)->
    Wallet.findUserWalletByCurrency orderToMatch.user_id, orderToMatch.buy_currency, (err, buyWallet)->
      Wallet.findUserWalletByCurrency orderToMatch.user_id, orderToMatch.sell_currency, (err, sellWallet)->
        matchedAmount = MarketHelper.convertFromBigint matchData.matched_amount
        resultAmount = MarketHelper.convertFromBigint matchData.result_amount
        unitPrice = MarketHelper.convertFromBigint matchData.unit_price
        fee = MarketHelper.convertFromBigint matchData.fee
        status = matchData.status
        holdBalance = if orderToMatch.action is "buy" then math.multiply(matchedAmount, orderToMatch.unit_price) else matchedAmount
        changeBalance = if orderToMatch.action is "buy" then math.add(holdBalance, -math.multiply(matchedAmount, unitPrice)) else 0
        sellWallet.addHoldBalance -holdBalance, transaction, (err, sellWallet)->
          return callback err  if err or not sellWallet
          sellWallet.addBalance changeBalance, transaction, (err, sellWallet)->
            return callback err  if err or not sellWallet
            buyWallet.addBalance resultAmount, transaction, (err, buyWallet)->
              return callback err  if err or not buyWallet
              orderToMatch.status = status
              orderToMatch.sold_amount = math.add orderToMatch.sold_amount, matchedAmount
              orderToMatch.result_amount = math.add orderToMatch.result_amount, resultAmount
              orderToMatch.fee = math.add orderToMatch.fee, fee
              orderToMatch.close_time = Date.now()  if status is "completed"
              orderToMatch.save({transaction: transaction}).complete (err, updatedOrder)->
                console.error "Could not process order ", err  if err
                return callback err  if err
                callback null, updatedOrder
                TradeHelper.pushUserUpdate
                  type: "wallet-balance-changed"
                  user_id: sellWallet.user_id
                  eventData: JsonRenderer.wallet sellWallet
                TradeHelper.pushUserUpdate
                  type: "wallet-balance-changed"
                  user_id: buyWallet.user_id
                  eventData: JsonRenderer.wallet buyWallet

  trackMatchedOrder: (order, callback = ()->)->
    if order.status is "completed"
      MarketStats.trackFromOrder order, (err, mkSt)->
        callback err, mkSt
        TradeHelper.send
          type: "market-stats-updated"
          eventData: mkSt.toJSON()
      TradeHelper.pushOrderUpdate
        type: "order-completed"
        eventData: JsonRenderer.order order
    if order.status is "partiallyCompleted"
      TradeHelper.pushOrderUpdate
        type: "order-partially-completed"
        eventData: JsonRenderer.order order
      callback()
    else
      callback()

exports = module.exports = TradeHelper