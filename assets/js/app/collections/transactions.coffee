class window.App.TransactionsCollection extends Backbone.Collection

  type: null

  walletId: null

  url: ()->
    url = "/transactions"
    url += "/#{@type}"  if @type
    url += "/#{@walletId}"  if @walletId
    url

  model: window.App.TransactionModel

  initialize: (models, options = {})->
    @type = options.type
    @walletId = options.walletId
