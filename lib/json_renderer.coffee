MarketHelper = require "./market_helper"
_ = require "underscore"
_str = require "underscore.string"

JsonRenderer =

  user: (user)->
    id:                 user.uuid
    email:              user.email
    username:           user.username
    gauth_qr:           user.gauth_qr
    gauth_key:          user.gauth_key
    chat_enabled:       user.chat_enabled
    email_auth_enabled: user.email_auth_enabled
    updated_at:         user.updated_at
    created_at:         user.created_at

  wallet: (wallet)->
    id:                wallet.id
    currency:          wallet.currency
    balance:           wallet.getFloat "balance"
    hold_balance:      wallet.getFloat "hold_balance"
    address:           wallet.address
    min_confirmations: wallet.network_confirmations
    updated_at:        wallet.updated_at
    created_at:        wallet.created_at

  wallets: (wallets)->
    data = []
    for wallet in wallets
      data.push @wallet wallet
    data

  payment: (payment)->
    id:             payment.id
    wallet_id:      payment.wallet_id
    transaction_id: payment.transaction_id
    address:        payment.address
    amount:         payment.getFloat "amount"
    currency:       payment.currency
    status:         payment.status
    updated_at:     payment.updated_at
    created_at:     payment.created_at

  payments: (payments)->
    data = []
    for payment in payments
      data.push @payment payment
    data

  transaction: (transaction)->
    id:                transaction.id
    wallet_id:         transaction.wallet_id
    currency:          transaction.currency
    fee:               transaction.getFloat "fee"
    address:           transaction.address
    amount:            transaction.getFloat "amount"
    category:          transaction.category
    txid:              transaction.txid
    confirmations:     transaction.confirmations
    min_confirmations: transaction.network_confirmations
    balance_loaded:    transaction.balance_loaded
    updated_at:        transaction.updated_at
    created_at:        transaction.created_at

  transactions: (transactions)->
    data = []
    for transaction in transactions
      data.push @transaction transaction
    data

  order: (order)->
    id:             order.id
    type:           order.type
    action:         order.action
    buy_currency:   order.buy_currency
    sell_currency:  order.sell_currency
    amount:         order.getFloat "amount"
    matched_amount: order.getFloat "matched_amount"
    result_amount:  order.getFloat "result_amount"
    fee:            order.getFloat "fee"
    unit_price:     order.getFloat "unit_price"
    status:         order.status
    published:      order.published
    updated_at:     order.updated_at
    created_at:     order.created_at

  orders: (orders)->
    data = []
    for order in orders
      data.push @order order
    data

  orderLog: (orderLog)->
    id:             orderLog.id
    order_id:       orderLog.order_id
    action:         orderLog.order.action
    buy_currency:   orderLog.order.buy_currency
    sell_currency:  orderLog.order.sell_currency
    matched_amount: orderLog.getFloat "matched_amount"
    result_amount:  orderLog.getFloat "result_amount"
    fee:            orderLog.getFloat "fee"
    unit_price:     orderLog.getFloat "unit_price"
    active:         orderLog.active
    time:           orderLog.time
    status:         orderLog.status
    updated_at:     orderLog.updated_at
    created_at:     orderLog.created_at

  orderLogs: (orderLogs)->
    data = []
    for orderLog in orderLogs
      data.push @orderLog orderLog
    data

  chatMessage: (message, user = {})->
    username = user.username
    username = message.user.username  if message.user?
    data =
      id: message.id
      message: message.message
      created_at: message.created_at
      updated_at: message.updated_at
      username: username

  chatMessages: (messages)->
    data = []
    for message in messages
      data.push @chatMessage message
    data

  marketStats: (marketStats)->
    for type, stats of marketStats
      stats.last_price = MarketHelper.fromBigint stats.last_price
      stats.day_high = MarketHelper.fromBigint stats.day_high
      stats.day_low = MarketHelper.fromBigint stats.day_low
      stats.volume1 = MarketHelper.fromBigint stats.volume1
      stats.volume2 = MarketHelper.fromBigint stats.volume2
      stats.growth_ratio = MarketHelper.fromBigint stats.growth_ratio
    marketStats

  tradeStats: (tradeStats)->
    for stats in tradeStats
      stats.open_price = MarketHelper.fromBigint stats.open_price
      stats.close_price = MarketHelper.fromBigint stats.close_price
      stats.high_price = MarketHelper.fromBigint stats.high_price
      stats.low_price = MarketHelper.fromBigint stats.low_price
      stats.volume = MarketHelper.fromBigint stats.volume
    tradeStats

  error: (err, res, code = 409, log = true)->
    console.error err  if log
    res.statusCode = code
    if _.isObject(err)
      delete err.sql
      return res.json {error: @formatError("#{err}")}  if err.code is "ER_DUP_ENTRY"
    message = ""
    if _.isString err
      message = err
    else if _.isObject(err)
      for key, val of err
        if _.isArray val
          message += "#{val.join(' ')} "
        else
          message += "#{val} "
    res.json {error: @formatError(message)}

  formatError: (message)->
    message = message.replace "Error: ER_DUP_ENTRY: ", ""
    message = message.replace /for key.*$/, ""
    message = message.replace /Duplicate entry/, "Value already taken"
    message = message.replace "ConflictError ", ""
    _str.trim message

exports = module.exports = JsonRenderer