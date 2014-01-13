_ = require "underscore"

JsonRenderer =

  user: (user)->
    id:      user.id
    email:   user.email
    created: user.created
    gauth_data: user.gauth_data

  wallet: (wallet)->
    id:       wallet.id
    user_id:  wallet.user_id
    currency: wallet.currency
    balance:  wallet.balance
    address:  wallet.address
    created:  wallet.created

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
    updated:        payment.updated
    created:        payment.created

  payments: (payments)->
    data = []
    for payment in payments
      data.push @payment payment
    data

  transaction: (transaction)->
    id:            transaction.id
    user_id:       transaction.user_id
    wallet_id:     transaction.wallet_id
    currency:      transaction.currency
    fee:           transaction.fee
    address:       transaction.address
    amount:        transaction.amount
    category:      transaction.category
    txid:          transaction.txid
    confirmations: transaction.confirmations
    created:       transaction.created

  transactions: (transactions)->
    data = []
    for transaction in transactions
      data.push @transaction transaction
    data

  order: (order)->
    id:            order.id
    user_id:       order.user_id
    type:          order.type
    action:        order.action
    buy_currency:  order.buy_currency
    sell_currency: order.sell_currency
    amount:        order.amount
    fee:           order.fee
    unit_price:    order.unit_price
    status:        order.status
    created:       order.created

  orders: (orders)->
    data = []
    for order in orders
      data.push @order order
    data

  error: (err, res, code = 409, log = true)->
    res.statusCode = code
    message = ""
    if _.isString err
      message = err
    else if _.isObject(err) and err.name is "ValidationError"
      for key, val of err.errors
        if val.path is "email" and val.message is "unique"
          message += "E-mail is already taken. "
        else
          message += "#{val.message} "
    res.json {error: message}
    console.error message  if log

exports = module.exports = JsonRenderer