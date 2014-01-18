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
    transactionsHistory = new App.TransactionsHistoryView
      el: $transactionsHistory
      collection: new App.TransactionsCollection null,
        type: "processed"
        walletId: $transactionsHistory.data "wallet-id"
    transactionsHistory.render()


  # Trade page
  $trade = $("#trade")
  if $trade.length
    trade = new App.TradeView
      el: $trade
    trade.render()

    $openOrders = $("#open-orders-cnt")
    openOrders = new App.OpenOrdersView
      el: $openOrders
      collection: new App.OrdersCollection null,
        type: "open"
        currency1: $openOrders.data "currency1"
        currency2: $openOrders.data "currency2"
    openOrders.render()

    $openSellOrders = $("#open-sell-orders-cnt")
    openSellOrders = new App.AllOpenOrdersView
      el: $openSellOrders
      collection: new App.OrdersCollection null,
        type: "open"
        action: "sell"
        currency1: $openSellOrders.data "currency1"
        currency2: $openSellOrders.data "currency2"
    openSellOrders.render()

    $openBuyOrders = $("#open-buy-orders-cnt")
    openBuyOrders = new App.AllOpenOrdersView
      el: $openBuyOrders
      collection: new App.OrdersCollection null,
        type: "open"
        action: "buy"
        currency1: $openBuyOrders.data "currency1"
        currency2: $openBuyOrders.data "currency2"
    openBuyOrders.render()

    $closedOrders = $("#closed-orders-cnt")
    closedOrders = new App.AllClosedOrdersView
      el: $closedOrders
      collection: new App.OrdersCollection null,
        type: "closed"
        action: "*"
        currency1: $openBuyOrders.data "currency1"
        currency2: $openBuyOrders.data "currency2"
    closedOrders.render()

