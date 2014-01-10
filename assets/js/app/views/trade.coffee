class App.TradeView extends App.MasterView

  events:
    "click .market-switcher": "onMarketSwitch"

  initialize: ()->
    $.subscribe "new-balance", @onNewBalance

  render: ()->
  
  onMarketSwitch: (ev)->
    console.log ev