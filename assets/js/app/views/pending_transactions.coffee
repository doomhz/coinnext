class App.PendingTransactionsView extends App.MasterView

  tpl: "pending-transaction-tpl"

  collection: null

  initialize: ()->
    $.subscribe "new-balance", @onNewBalance

  render: ()->
    @collection.fetch
      success: ()=>
        @collection.each (transaction)=>
          @$el.append @template
            transaction: transaction

  onNewBalance: (ev, data)=>
    #TODO: Implement
