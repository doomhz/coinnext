class App.MarketTickerView extends App.MasterView

  model: null

  tpl: "market-ticker-tpl"

  activeCurrency: null

  initialize: (options = {})->
    $.subscribe "market-stats-updated", @onMarketStatsUpdated

  render: ()->
    @model.fetch
      success: ()=>
        @renderMarketTicker()
      error: ()=>

  renderMarketTicker: ()->
    @$el.html @template
      marketStats: @model
    @markActive()

  markActive: (currency = null)->
    @activeCurrency = currency  if currency
    @$("[data-market-currency='#{@activeCurrency}']").addClass "active"

  onMarketStatsUpdated: (ev, data)=>
    @render()
