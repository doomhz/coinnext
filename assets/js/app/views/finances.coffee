class App.FinancesView extends App.MasterView

  events:
    "submit #add-wallet-form": "onAddWallet"
    "click #show-qr-bt": "onShowQrAddress"
    "click #generate-address": "onGenerateAddress"
    "submit #withdraw-form": "onPay"

  initialize: ()->
    $.subscribe "payment-processed", @onPaymentProcessed
    $.subscribe "wallet-balance-loaded", @onWalletBalanceLoaded

  render: ()->
    @renderCopyButton()

  renderCopyButton: ()->
    $copyButton = @$("#copy-address")
    $showQrBt = @$("#show-qr-bt")
    if $copyButton.length and $copyButton.data("clipboard-text").length
      new ZeroClipboard $copyButton[0],
        moviePath: "#{window.location.origin}/ZeroClipboard.swf"
      $copyButton.show()
      $showQrBt.show()
    else
      $copyButton.hide()
      $showQrBt.hide()

  renderQrAddress: ($qrCnt)->
    $qrCnt.empty()
    new QRCode $qrCnt[0], $qrCnt.data("address")

  renderWalletBalance: (walletId)->
    wallet = new App.WalletModel
      id: walletId
    wallet.fetch
      success: ()=>
        @$("[data-wallet-balance-id='#{walletId}']").html _.str.satoshiRound(wallet.get("balance") + wallet.get("hold_balance"))
        @$("[data-wallet-hold-balance-id='#{walletId}']").text _.str.satoshiRound(wallet.get("hold_balance"))
        @$("[data-wallet-available-balance-id='#{walletId}']").text _.str.satoshiRound(wallet.get("balance"))

  onAddWallet: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    wallet = new App.WalletModel
      currency: $form.find("#currency-type").val()
    wallet.save null,
      success: ()->
        window.location.reload()
      error: (m, xhr)->
        $.publish "error", xhr

  onShowQrAddress: (ev)->
    ev.preventDefault()
    $qrCnt = @$("#qr-address-cnt")
    if $qrCnt.is ":empty"
      @renderQrAddress $qrCnt
    else
      $qrCnt.toggle()

  onGenerateAddress: (ev)->
    ev.preventDefault()
    $target = $(ev.target)
    wallet = new App.WalletModel
      id: $target.data "id"
    wallet.save {address: "pending"},
      success: ()=>
        $copyButton = @$("#copy-address")
        $addressRow = @$("#address-row")
        $qrAddressCnt = @$("#qr-address-cnt")
        $showQrBt = @$("#show-qr-bt")
        $copyButton.attr "data-clipboard-text", wallet.get("address")
        $copyButton.data "clipboard-text", wallet.get("address")
        $addressRow.text wallet.get("address")
        $qrAddressCnt.attr "data-address", wallet.get("address")
        $qrAddressCnt.data "address", wallet.get("address")
        $copyButton.show()
        $showQrBt.show()
        @renderCopyButton()
        @$("#generate-address").remove()
      error: (m, xhr)->
        $.publish "error", xhr    

  onPay: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    amount = parseFloat $form.find("[name='amount']").val()
    if _.isNumber(amount) and amount > 0
      $form.find("button").attr "disabled", true
      payment = new App.PaymentModel
        wallet_id: $form.find("[name='wallet_id']").val()
        amount: amount
        address: $form.find("[name='address']").val()
      payment.save null,
        success: ()->
          $form.find("button").attr "disabled", false
          $.publish "notice", "Your withdrawal will be processed soon."
          $.publish "payment-submited", payment
        error: (m, xhr)->
          $form.find("button").attr "disabled", false
          $.publish "error", xhr
    else
      $.publish "error", "Please submit a proper amount."

  onPaymentProcessed: (ev, payment)=>
    @renderWalletBalance payment.get("wallet_id")

  onWalletBalanceLoaded: (ev, wallet)=>
    @renderWalletBalance wallet.id
