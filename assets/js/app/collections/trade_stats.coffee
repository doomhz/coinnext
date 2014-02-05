class window.App.TradeStatsCollection extends Backbone.Collection

  type: null

  url: ()->
    "/trade_stats/#{@type}"

  initialize: (models, options = {})->
    @type = options.type