class App.TransactionsHistoryView extends App.MasterView

  tpl: "transaction-history-tpl"

  collection: null

  initialize: (options = {})->
    $.subscribe "new-balance", @onNewBalance

  render: ()->
    @collection.fetch
      success: ()=>
        @collection.each (transaction)=>
          @$el.append @template
            transaction: transaction

  onNewBalance: (ev, data)=>
    #TODO: Implement
