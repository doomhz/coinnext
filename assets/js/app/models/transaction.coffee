window.App or= {}

class App.TransactionModel extends Backbone.Model

  urlRoot: "/transactions"

  getCreatedDate: ()->
    new Date(@get('created_at')).format('dd.mm.yy H:MM')