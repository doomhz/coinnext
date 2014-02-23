class App.PendingTransactionsView extends App.MasterView

  tpl: "pending-transaction-tpl"

  collection: null

  payments: null

  initialize: (options = {})->
    $.subscribe "payment-processed", @onPaymentProcessed
    $.subscribe "transaction-update", @onTransactionUpdate
    @payments = options.payments

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

  onTransactionUpdate: (ev, transaction)=>
    @$el.empty()
    @render()

  onPaymentProcessed: (ev, payment)=>
    @$el.empty()
    @render()  if @$("[data-id='#{payment.id}']").length
