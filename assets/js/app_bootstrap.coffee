$(document).ready ()->

  $.tmpload.defaults.tplWrapper = _.template
  $(document).ajaxSend (ev, xhr)->
    xhr.setRequestHeader "X-CSRF-Token", CONFIG.csrf
  App.math = mathjs
    number: "bignumber"
    decimals: 8

  _.str.roundTo = (number, decimals = 8)->
    App.math.round parseFloat(number), decimals

  _.str.satoshiRound = (number)->
    _.str.roundTo number, 8

  _.str.toFixed = (number, decimals = 8)->
    parseFloat(number).toFixed(decimals)

  errorLogger = new App.ErrorLogger

  user = new App.UserModel
  user.fetch
    success: ()->
      if user.id
        usersSocket = io.connect "#{CONFIG.users.hostname}/users"
        usersSocket.on "payment-processed", (data)=>
          payment = new App.PaymentModel data
          $.publish "payment-processed", payment
        usersSocket.on "transaction-update", (data)=>
          transaction = new App.TransactionModel data
          $.publish "transaction-update", transaction
        usersSocket.on "wallet-balance-loaded", (data)=>
          wallet = new App.WalletModel data
          $.publish "wallet-balance-loaded", wallet
        usersSocket.on "wallet-balance-changed", (data)=>
          wallet = new App.WalletModel data
          $.publish "wallet-balance-changed", wallet

  $(".amount-field").keyup (ev)->
    $target = $(ev.target)
    amount = $target.val()
    if amount.indexOf(".") > -1
      decimals = amount.substr amount.indexOf(".") + 1
      if decimals.length > 8
        integer = amount.substr 0, amount.indexOf(".")
        decimals = decimals.substr 0, 8
        $target.val "#{integer}.#{decimals}"

  # Settings page
  $settings = $("#settings")
  if $settings.length
    settings = new App.SettingsView
      el: $settings
      model: user

  $marketTicker = $("#market-ticker")
  if $marketTicker.length
    marketTicker = new App.MarketTickerView
      el: $marketTicker
      model: new App.MarketStatsModel
    #marketTicker.render()

  # Funds page
  $finances = $("#finances")
  if $finances.length
    finances = new App.FinancesView
      el: $finances
      collection: new App.WalletsCollection
    finances.render()

    $pendingTransactions = $("#pending-transactions-cnt")
    if $pendingTransactions.length
      pendingTransactions = new App.PendingTransactionsView
        el: $pendingTransactions
        collection: new App.TransactionsCollection null,
          type: "pending"
          walletId: $pendingTransactions.data "wallet-id"
        payments: new App.PaymentsCollection null,
          type: "pending"
          walletId: $pendingTransactions.data "wallet-id"
        hideOnEmpty: true
      pendingTransactions.render()

    $transactionsHistory = $("#transactions-history-cnt")
    if $transactionsHistory.length
      transactionsHistory = new App.TransactionsHistoryView
        el: $transactionsHistory
        collection: new App.TransactionsCollection null,
          type: "processed"
          walletId: $transactionsHistory.data "wallet-id"
        hideOnEmpty: true
      transactionsHistory.render()

    $openOrders = $("#open-orders-cnt")
    if $openOrders.length
      openOrders = new App.OrdersView
        el: $openOrders
        tpl: "wallet-open-order-tpl"
        collection: new App.OrdersCollection null,
          type: "open"
          currency1: $openOrders.data "currency1"
          userId: CONFIG.currentUser.id
        hideOnEmpty: true
      openOrders.render()

    $closedOrders = $("#closed-orders-cnt")
    if $closedOrders.length
      closedOrders = new App.OrderLogsView
        el: $closedOrders
        tpl: "wallet-closed-order-tpl"
        collection: new App.OrdersCollection null,
          type: "completed"
          currency1: $closedOrders.data "currency1"
          userId: CONFIG.currentUser.id
        hideOnEmpty: true
      closedOrders.render()

    $overviewOpenOrders = $("#overview-open-orders-cnt")
    if $overviewOpenOrders.length
      overviewOpenOrders = new App.OrdersView
        el: $overviewOpenOrders
        tpl: "wallet-open-order-tpl"
        collection: new App.OrdersCollection null,
          type: "open"
          userId: CONFIG.currentUser.id
        hideOnEmpty: true
      overviewOpenOrders.render()

    $overviewClosedOrders = $("#overview-closed-orders-cnt")
    if $overviewClosedOrders.length
      overviewClosedOrders = new App.OrderLogsView
        el: $overviewClosedOrders
        tpl: "wallet-closed-order-tpl"
        collection: new App.OrderLogsCollection null,
          userId: CONFIG.currentUser.id
        hideOnEmpty: true
      overviewClosedOrders.render()


  # Trade page
  $trade = $("#trade")
  if $trade.length
    marketTicker.markActive $trade.data "currency1"  if $marketTicker.length
    
    trade = new App.TradeView
      el: $trade
      model: new App.MarketStatsModel
      currency1: $trade.data "currency1"
      currency2: $trade.data "currency2"
    trade.setupFormValidators()

    tradeChart = new App.TradeChartView
      el: $trade.find("#trade-chart")
      collection: new App.TradeStatsCollection null,
        type: "#{$trade.data('currency1')}_#{$trade.data('currency2')}"
    tradeChart.render()

    $openOrders = $("#open-orders-cnt")
    openOrders = new App.OrdersView
      el: $openOrders
      tpl: "open-order-tpl"
      collection: new App.OrdersCollection null,
        type: "open"
        currency1: $openOrders.data "currency1"
        currency2: $openOrders.data "currency2"
        userId: CONFIG.currentUser.id or "guest"
      hideOnEmpty: true
    openOrders.render()

    $orderBookSell = $("#order-book-sell-cnt")
    orderBookSell = new App.OrderBookView
      el: $orderBookSell
      tpl: "order-book-order-tpl"
      $totalsEl: $trade.find("#order-book-sell-volume-total")
      collection: new App.OrdersCollection null,
        type: "open"
        action: "sell"
        currency1: $orderBookSell.data "currency1"
        currency2: $orderBookSell.data "currency2"
        published: true
        orderBy: [
          ["unit_price", "ASC"]
          ["created_at", "ASC"]
        ]
    orderBookSell.render()

    $orderBookBuy = $("#order-book-buy-cnt")
    orderBookBuy = new App.OrderBookView
      el: $orderBookBuy
      tpl: "order-book-order-tpl"
      $totalsEl: $trade.find("#order-book-buy-volume-total")
      collection: new App.OrdersCollection null,
        type: "open"
        action: "buy"
        currency1: $orderBookBuy.data "currency1"
        currency2: $orderBookBuy.data "currency2"
        published: true
        orderBy: [
          ["unit_price", "DESC"]
          ["created_at", "ASC"]
        ]
    orderBookBuy.render()

    $closedOrders = $("#closed-orders-cnt")
    closedOrders = new App.OrderLogsView
      el: $closedOrders
      tpl: "site-closed-order-tpl"
      collection: new App.OrderLogsCollection null,
        type: "completed"
        currency1: $closedOrders.data "currency1"
        currency2: $closedOrders.data "currency2"
      hideOnEmpty: true
    closedOrders.render()

  ordersSocket = io.connect "#{CONFIG.users.hostname}/orders"
  ordersSocket.on "connect", ()->
  ordersSocket.on "order-published", (data)->
    order = new App.OrderModel data
    $.publish "new-order", order
  ordersSocket.on "order-completed", (data)->
    order = new App.OrderModel data
    $.publish "order-completed", order
  ordersSocket.on "order-partially-completed", (data)->
    order = new App.OrderModel data
    $.publish "order-partially-completed", order
  ordersSocket.on "order-canceled", (data)->
    $.publish "order-canceled", data
  ordersSocket.on "order-to-cancel", (data)->
    $.publish "order-to-cancel", data
  ordersSocket.on "order-to-add", (data)->
    $.publish "order-to-add", data
  ordersSocket.on "market-stats-updated", (data)->
    $.publish "market-stats-updated", data
