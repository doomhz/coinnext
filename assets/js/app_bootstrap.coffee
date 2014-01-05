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
    pendingTransactions.render()
