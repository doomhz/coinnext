class App.ChatMessagesCollection extends Backbone.Collection

  model: App.ChatMessageModel

  room: null

  rootUrl: "/chat/messages"

  initialize: (models, options)->
    @room = options.room

  url: ()->
    "#{@rootUrl}/#{@room}"