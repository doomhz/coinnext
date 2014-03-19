class App.ChatMessagesCollection extends Backbone.Collection

  model: App.ChatMessageModel

  url: "/chat/messages"

  initialize: (models, options)->

