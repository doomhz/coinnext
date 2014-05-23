$(document).ready ()->
  $.tmpload.defaults.tplWrapper = _.template
  $(document).ajaxSend (ev, xhr)->
    xhr.setRequestHeader "X-CSRF-Token", CONFIG.csrf
  window.App = window.App or {}
  
  rootUrl = "/administratie"
  
  $btcBankBalance = $("#bank-balance-BTC")
  if $btcBankBalance.length
    updateBankBalance = ()->
      defer = $.Deferred()
      updateBalanceByCurrency = (currency, index)->
        defer.then ()->
          setTimeout ()->
              $.getJSON "#{rootUrl}/banksaldo/#{currency}", (response)->
                balance = if _.isNumber(response.balance) then _.str.numberFormat(response.balance, 3) else response.balance
                $("#bank-balance-#{response.currency}").text balance
            , index * 500
      index = 1
      for currency in CONFIG.currencies
        updateBalanceByCurrency currency, index
        index++
      defer.resolve()
    setInterval updateBankBalance, 60000
    updateBankBalance()

    $(".show-wallet-info-bt").click (ev)->
      ev.preventDefault()
      currency = $(ev.target).data "currency"
      $cnt = $("#wallet-info-cnt-#{currency}")
      if not $cnt.hasClass("hidden")
        $cnt.addClass "hidden"
      else
        $.post "#{rootUrl}/wallet_info", {currency: currency}, (response)->
          $("#wallet-address-#{currency}").html response.address
          $("#wallet-info-#{currency}").html window.App.Helpers.JSON.toHTML response.info
          $cnt.removeClass "hidden"


  $searchUserForm = $("#search-user-form")
  if $searchUserForm.length
    $searchUserForm.submit (ev)->
      ev.preventDefault()
      $.post "#{rootUrl}/search_user", $(ev.target).serialize(), (response)->
        if response.id
          $("#search-user-result")
          .attr("href", "#{rootUrl}/user/#{response.id}")
          .text "#{response.id} - #{response.email}"
        else
          alert "User could not be found."

  $transactionsTable = $("#transactions")
  if $transactionsTable.length
    $transactionsTable.delegate ".transaction-log-toggler", "click", (ev)->
      ev.preventDefault()
      $logEl = $(ev.currentTarget).next(".transaction-log:first")
      $logEl.toggleClass "hidden", not $logEl.hasClass("hidden")

  $paymentsTable = $("#payments")
  if $paymentsTable.length
    $paymentsTable.delegate ".payment-log-toggler", "click", (ev)->
      ev.preventDefault()
      $logEl = $(ev.currentTarget).next(".payment-log:first")
      $logEl.toggleClass "hidden", not $logEl.hasClass("hidden")

    $paymentsTable.delegate ".pay", "click", (ev)->
      ev.preventDefault()
      $el = $(ev.currentTarget)
      $.ajax
        url: "#{rootUrl}/pay/#{$el.data('id')}"
        type: "put"
        dataType: "json"
        success: (response)->
          $el.parent().find(".payment-status").text response.status
          $el.parent().find("button").hide()
        error: (xhr)->
          alert xhr.responseText

    $paymentsTable.delegate ".remove", "click", (ev)->
      ev.preventDefault()
      if confirm "Are you sure?"
        $el = $(ev.currentTarget)
        $.ajax
          url: "#{rootUrl}/payment/#{$el.data('id')}"
          type: "delete"
          dataType: "json"
          success: (response)->
            $el.parent().find(".payment-status").text response.status
            $el.parent().find("button").hide()
          error: (xhr)->
            alert xhr.responseText

  $markets = $("#markets")
  if $markets.length
    $markets.delegate ".market-switcher", "click", (ev)->
      ev.preventDefault()
      $el = $(ev.currentTarget)
      $.ajax
        url: "#{rootUrl}/markets/#{$el.data('id')}"
        type: "put"
        dataType: "json"
        data:
          status: $el.data "status"
        success: (response)->
          window.location.reload()

  $resendEmailVerificationBt = $("#resend-email-verification")
  if $resendEmailVerificationBt.length
    $resendEmailVerificationBt.click (ev)->
      return  if not confirm "Are you sure?"
      $target = $(ev.target)
      $.post "#{rootUrl}/resend_user_verification_email/#{$target.data("id")}", (response)->
        if response.user_id
          alert "Verification successfully sent."
        else
          alert xhr.responseText