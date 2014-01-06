class window.App.PaymentsCollection extends Backbone.Collection

  type: null

  walletId: null

  url: ()->
    url = "/payments"
    url += "/#{@type}"  if @type
    url += "/#{@walletId}"  if @walletId
    url

  model: window.App.PaymentModel

  initialize: (models, options = {})->
    @type = options.type
    @walletId = options.walletId
