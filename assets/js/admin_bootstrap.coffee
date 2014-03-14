$(document).ready ()->
  $.tmpload.defaults.tplWrapper = _.template
  window.App = window.App or {}
  
  rootUrl = "/administratie"
  
  $btcBankBalance = $("#btc-bank-balance")
  $dogeBankBalance = $("#doge-bank-balance")
  $ltcBankBalance = $("#ltc-bank-balance")
  if $btcBankBalance.length
    updateBankBalance = ()->
      $.getJSON "#{rootUrl}/banksaldo", (response)->
        $btcBankBalance.text _.str.numberFormat(response.btcBankBalance, 3)
        $dogeBankBalance.text _.str.numberFormat(response.dogeBankBalance, 3)
        $ltcBankBalance.text _.str.numberFormat(response.ltcBankBalance, 3)
    setInterval updateBankBalance, 60000
    updateBankBalance()

  $("#show-wallet-info").click (ev)->
    ev.preventDefault()
    $("#wallet-info").toggleClass "hidden"

  $findUserBt = $("#find-user-bt")
  if $findUserBt.length
    $findUserBt.click ()->
      $.post "#{rootUrl}/search_user", {term: $("input[name='user-search']").val()}, (response)->
        if response.id
          $("#search-user-result")
          .attr("href", "#{rootUrl}/user/#{response.id}")
          .text response.id
        else
          alert "User could not be found."
