class App.FinancesView extends App.MasterView

  tpl: "wallet-tpl"

  events:
    "submit #add-wallet-form": "onAddWallet"
    "click .deposit-bt": "onDeposit"
    "click .withdraw-bt": "onWithdraw"
    "click .show-qr-address": "onShowQrAddress"
    "submit #withdraw-form": "onPay"

  initialize: ()->

  render: ()->
    @renderWallets()

  renderWallets: ()=>
    @collection.fetch
      success: ()=>
        @renderWallet wallet for wallet in @collection.models

  renderWallet: (wallet)->
    $wallet = @$("[data-id='#{wallet.id}']")
    $walletEl = @template
      wallet: wallet
    if $wallet.length
      $wallet.replaceWith $walletEl
    else
      @$("#wallets").prepend $walletEl

  renderQrAddress: ($qrCnt)->
    $qrCnt.empty()
    new QRCode $qrCnt[0], $qrCnt.data("address")

  onAddWallet: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    wallet = new App.WalletModel
      currency: $form.find("#currency-type").val()
    wallet.save null,
      success: @renderWallets
      error: (m, xhr)->
        $.publish "error", xhr

  onDeposit: (ev)->
    ev.preventDefault()
    $target = $(ev.target)
    wallet = @collection.get $target.data "id"
    wallet.save {address: "pending"},
      success: ()=>
        @renderWallet wallet
      error: (m, xhr)->
        $.publish "error", xhr

  onShowQrAddress: (ev)->
    ev.preventDefault()
    $target = $(ev.target)
    walletId = $target.data "id"
    $qrCnt = @$(".qr-address[data-id='#{walletId}']")
    if $qrCnt.is ":empty"
      @renderQrAddress $qrCnt
    else
      $qrCnt.toggle()  

  onWithdraw: (ev)->
    $target = $(ev.target)
    $target.parents(".wallet:first")
    .find(".withdraw-cnt").slideToggle()

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
          $form.parent().slideToggle()
          $.publish "notice", "Your withdrawal will be processed soon."
        error: (m, xhr)->
          $form.find("button").attr "disabled", false
          $.publish "error", xhr
    else
      $.publish "error", "Please submit a proper amount."
