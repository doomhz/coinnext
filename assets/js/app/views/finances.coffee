class App.FinancesView extends Backbone.View

  tpl: "wallets-tpl"

  events:
    "#add-wallet-form submit": "onAddWallet"

  initialize: ()->

  render: ()->
    @collection.fetch
      success: @renderWallets

  renderWallets: ()=>
    tpl = $.tmpload
      id: @tpl
    @$("#wallets").html tpl
      wallets: @collection

  onAddWallet: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    wallet = new App.WalletModel
      currency: $form.find("#currency-type").val()
    wallet.save null,
      success: @renderWallets
      error: ()->
        console.log arguments
