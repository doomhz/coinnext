class App.MarketTickerView extends App.MasterView

  model: null

  tpl: "market-ticker-tpl"

  initialize: (options = {})->
    $.subscribe "new-balance", @onNewBalance
    $.subscribe "market-stats-updated", @onMarketStatsUpdated

  render: ()->
    @model.fetch
      success: ()=>
        @renderMaketTicker()
      error: ()=>

  renderMaketTicker: ()->
    @$el.html @template
      marketStats: @model

  onMarketStatsUpdated: (ev, data)=>
    @render()
