$(document).ready ()->
  
  $.tmpload.defaults.tplWrapper = _.template

  window.App = window.App or {}

  user = new App.UserModel

  $globalChat = $("#globalchat")
  
  if $globalChat.length
    user.fetch
      success: ()->
        globalChat = new App.ChatView
          el: $globalChat
          user: user
          chatSocketUrl: "/chat"
          messageHistoryRootUrl: "/chat/messages"
          room: "global"
        globalChat.render()
