window.App or= {}

class App.TransactionModel extends Backbone.Model

  urlRoot: "/transactions"

  getCreatedDate: ()->
    new Date(@get('created')).format('dd.mm.yy hh:mm')