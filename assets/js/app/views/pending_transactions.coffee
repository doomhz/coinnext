class App.PendingTransactionsView extends App.MasterView

  tpl: "pending-transaction-tpl"

  collection: null

  payments: null

  initialize: (options = {})->
    @payments = options.payments
    @hideOnEmpty = options.hideOnEmpty  if options.hideOnEmpty
    @toggleVisible()
    $.subscribe "payment-submited", @onPaymentSubmited
    $.subscribe "payment-processed", @onPaymentProcessed
    $.subscribe "transaction-update", @onTransactionUpdate

  render: ()->
    @collection.fetch
      success: ()=>
        @collection.each (transaction)=>
          $tx = @template
            transaction: transaction
          $existentTx = @$("[data-id='#{transaction.id}']")
          if not $existentTx.length
            @$el.append $tx
          else
            $existentTx.replaceWith $tx
        @toggleVisible()  if @hideOnEmpty
    @payments.fetch
      success: ()=>
        @payments.each (payment)=>
          $pm = @template
            payment: payment
          $existentPm = @$("[data-id='#{payment.id}']")
          if not $existentPm.length
            @$el.append $pm
          else
            $existentPm.replaceWith $pm
        @toggleVisible()  if @hideOnEmpty

  onTransactionUpdate: (ev, transaction)=>
    @render()
    @$("[data-id='#{transaction.id}']").remove()  if transaction.get("balance_loaded")

  onPaymentProcessed: (ev, payment)=>
    @render()
    @$("[data-id='#{payment.id}']").remove()

  onPaymentSubmited: (ev, payment)=>
    @render()
