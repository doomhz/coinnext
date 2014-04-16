_ = require "underscore"
_str = require "underscore.string"

JsonRenderer =

  user: (user)->
    uuid:               user.uuid
    id:                 user.id
    email:              user.email
    username:           user.username
    gauth_qr:           user.gauth_qr
    gauth_key:          user.gauth_key
    chat_enabled:       user.chat_enabled
    email_auth_enabled: user.email_auth_enabled
    updated_at:         user.updated_at
    created_at:         user.created_at

  wallet: (wallet)->
    id:            wallet.id
    user_id:       wallet.user_id
    currency:      wallet.currency
    balance:       wallet.balance
    hold_balance:  wallet.hold_balance
    address:       wallet.address
    updated_at:    wallet.updated_at
    created_at:    wallet.created_at

  wallets: (wallets)->
    data = []
    for wallet in wallets
      data.push @wallet wallet
    data

  payment: (payment)->
    id:             payment.id
    user_id:        payment.user_id
    wallet_id:      payment.wallet_id
    transaction_id: payment.transaction_id
    address:        payment.address
    amount:         payment.amount
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
    id:             transaction.id
    user_id:        transaction.user_id
    wallet_id:      transaction.wallet_id
    currency:       transaction.currency
    fee:            transaction.fee
    address:        transaction.address
    amount:         transaction.amount
    category:       transaction.category
    txid:           transaction.txid
    confirmations:  transaction.confirmations
    balance_loaded: transaction.balance_loaded
    updated_at:     transaction.updated_at
    created_at:     transaction.created_at

  transactions: (transactions)->
    data = []
    for transaction in transactions
      data.push @transaction transaction
    data

  order: (order)->
    id:             order.id
    user_id:        order.user_id
    type:           order.type
    action:         order.action
    buy_currency:   order.buy_currency
    sell_currency:  order.sell_currency
    amount:         order.amount
    matched_amount: order.matched_amount
    result_amount:  order.result_amount
    fee:            order.fee
    unit_price:     order.unit_price
    status:         order.status
    published:      order.published
    updated_at:     order.updated_at
    created_at:     order.created_at

  orders: (orders)->
    data = []
    for order in orders
      data.push @order order
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

  error: (err, res, code = 409, log = true)->
    console.error err  if log
    res.statusCode = code
    if _.isObject(err)
      delete err.sql
      return res.json {error: @formatDuplicateError("#{err}")}  if err.code is "ER_DUP_ENTRY"
    message = ""
    if _.isString err
      message = err
    else if _.isObject(err)
      for key, val of err
        if _.isArray val
          message += "#{val.join(' ')} "
        else
          message += "#{val} "
    res.json {error: @formatDuplicateError(message)}

  formatDuplicateError: (message)->
    message = message.replace "Error: ER_DUP_ENTRY: ", ""
    message = message.replace /for key.*$/, ""
    message = message.replace /Duplicate entry/, "Value already taken"
    _str.trim message

exports = module.exports = JsonRenderer