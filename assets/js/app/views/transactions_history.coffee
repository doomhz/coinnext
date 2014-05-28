class App.TransactionsHistoryView extends App.MasterView

  tpl: "transaction-history-tpl"

  collection: null

  initialize: (options = {})->
    @hideOnEmpty = options.hideOnEmpty  if options.hideOnEmpty
    @toggleVisible()
    $.subscribe "payment-processed", @onPaymentProcessed
    $.subscribe "transaction-update", @onTransactionUpdate

  render: ()->
    @collection.fetch
      success: ()=>
        @renderTransactions()
        @toggleVisible()  if @hideOnEmpty

  renderTransactions: ()->
    @collection.each (transaction)=>
      $existentTransaction = @$("[data-id='#{transaction.id}']")
      tpl = @template
        transaction: transaction
      @$el.append tpl  if not $existentTransaction.length
      $existentTransaction.replaceWith tpl  if $existentTransaction.length

  onTransactionUpdate: (ev, transaction)=>
    @render()

  onPaymentProcessed: (ev, payment)=>
    @render()
