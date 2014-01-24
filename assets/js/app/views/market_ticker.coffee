class App.MarketTickerView extends App.MasterView

  model: null

  tpl: "market-ticker-tpl"

  initialize: (options = {})->
    $.subscribe "new-balance", @onNewBalance

  render: ()->
    @model.fetch
      success: ()=>
        @renderMaketTicker()
      error: ()=>

  renderMaketTicker: ()->
    @$el.html @template
      marketStats: @model
