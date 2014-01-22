$(document).ready ()->

  $.tmpload.defaults.tplWrapper = _.template

  errorLogger = new App.ErrorLogger

  user = new App.UserModel
  user.listenToEvents()

  $qrGenBt = $("#qr-gen-bt")

  if $qrGenBt.length
    $qrGenBt.click (ev)->
      ev.preventDefault()
      if confirm "Are you sure?"
        $.get $qrGenBt.attr("href"), ()->
          window.location.reload()

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
      pendingTransactions.render()

    $transactionsHistory = $("#transactions-history-cnt")
    if $transactionsHistory.length
      transactionsHistory = new App.TransactionsHistoryView
        el: $transactionsHistory
        collection: new App.TransactionsCollection null,
          type: "processed"
          walletId: $transactionsHistory.data "wallet-id"
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
      openOrders.render()

    $closedOrders = $("#closed-orders-cnt")
    if $closedOrders.length
      closedOrders = new App.OrdersView
        el: $closedOrders
        tpl: "wallet-closed-order-tpl"
        collection: new App.OrdersCollection null,
          type: "closed"
          currency1: $closedOrders.data "currency1"
          userId: CONFIG.currentUser.id
      closedOrders.render()

    $overviewOpenOrders = $("#overview-open-orders-cnt")
    if $overviewOpenOrders.length
      overviewOpenOrders = new App.OrdersView
        el: $overviewOpenOrders
        tpl: "wallet-open-order-tpl"
        collection: new App.OrdersCollection null,
          type: "open"
          userId: CONFIG.currentUser.id
      overviewOpenOrders.render()

    $overviewClosedOrders = $("#overview-closed-orders-cnt")
    if $overviewClosedOrders.length
      overviewClosedOrders = new App.OrdersView
        el: $overviewClosedOrders
        tpl: "wallet-closed-order-tpl"
        collection: new App.OrdersCollection null,
          type: "closed"
          userId: CONFIG.currentUser.id
      overviewClosedOrders.render()


  # Trade page
  $trade = $("#trade")
  if $trade.length
    trade = new App.TradeView
      el: $trade
    trade.render()

    $openOrders = $("#open-orders-cnt")
    openOrders = new App.OrdersView
      el: $openOrders
      tpl: "open-order-tpl"
      collection: new App.OrdersCollection null,
        type: "open"
        currency1: $openOrders.data "currency1"
        currency2: $openOrders.data "currency2"
        userId: CONFIG.currentUser.id
    openOrders.render()  if CONFIG.currentUser.id

    $openSellOrders = $("#open-sell-orders-cnt")
    openSellOrders = new App.OrdersView
      el: $openSellOrders
      tpl: "site-open-order-tpl"
      collection: new App.OrdersCollection null,
        type: "open"
        action: "sell"
        currency1: $openSellOrders.data "currency1"
        currency2: $openSellOrders.data "currency2"
    openSellOrders.render()  if CONFIG.currentUser.id

    $openBuyOrders = $("#open-buy-orders-cnt")
    openBuyOrders = new App.OrdersView
      el: $openBuyOrders
      tpl: "site-open-order-tpl"
      collection: new App.OrdersCollection null,
        type: "open"
        action: "buy"
        currency1: $openBuyOrders.data "currency1"
        currency2: $openBuyOrders.data "currency2"
    openBuyOrders.render()  if CONFIG.currentUser.id

    $closedOrders = $("#closed-orders-cnt")
    closedOrders = new App.OrdersView
      el: $closedOrders
      tpl: "site-closed-order-tpl"
      collection: new App.OrdersCollection null,
        type: "closed"
        currency1: $openBuyOrders.data "currency1"
        currency2: $openBuyOrders.data "currency2"
    closedOrders.render()  if CONFIG.currentUser.id

