class App.FinancesView extends App.MasterView

  tpl: "wallet-tpl"

  events:
    "submit #add-wallet-form": "onAddWallet"
    "click #generate-wallet-address": "onGenerateAddress"
    "click #show-qr-address": "onShowQrAddress"

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

  onGenerateAddress: (ev)->
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
    @renderQrAddress @$(".qr-address[data-id='#{walletId}']")
