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
  if $finances
    finances = new App.FinancesView
      el: $finances
      collection: new App.WalletsCollection
    finances.render()
