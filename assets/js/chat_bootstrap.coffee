$(document).ready ()->
  
  $.tmpload.defaults.tplWrapper = _.template

  window.App = window.App or {}

  user = new App.UserModel

  $globalChat = $("#globalchat")
  
  if $globalChat.length
    user.fetch
      complete: ()->
        globalChat = new App.ChatView
          el: $globalChat
          user: user
          chatSocketUrl: "#{CONFIG.users.hostname}/chat"
          messageHistoryRootUrl: "/chat/messages"
        globalChat.render()
