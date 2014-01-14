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

  $trade = $("#trade")
  if $trade.length
    trade = new App.TradeView
      el: $trade
    trade.render()

  $openOrders = $("#open-orders-cnt")
  if $openOrders.length
    openOrders = new App.OpenOrdersView
      el: $openOrders
      collection: new App.OrdersCollection null,
        type: "open"
        currency1: $openOrders.data "currency1"
        currency2: $openOrders.data "currency2"
    openOrders.render()

