class App.ChatView extends App.MasterView

  tpl: "chat-message-tpl"

  chatSocketUrl: null

  messageHistoryRootUrl: null

  events:
    "keydown #chat-message-box": "onMessageTyping"
    "click #send-message-bt": "onSendClick"
  
  initialize: ({@user, @chatSocketUrl, @messageHistoryRootUrl})->
    @chatSocketUrl ?= "/chat"

  render: ()->
    @loadHistory()
    @socket = io.connect @chatSocketUrl
    @socket.on "connect", ()=>
    #  @socket.emit "join"
    @socket.on "new-message", (data)=>
      #console.log data
      @renderMessage data

  loadHistory: ()->
    messagesCollection = new App.ChatMessagesCollection null, {room: @room}
    messagesCollection.rootUrl = @messageHistoryRootUrl  if @messageHistoryRootUrl
    messagesCollection.fetch
      success: ()=>
        messagesCollection.each (message)=>
          @renderMessage message, "prepend"

  renderMessage: (message = {}, mode = "append")->
    if not (message instanceof App.ChatMessageModel)
      message = new App.ChatMessageModel message
    $message = $(@template({message: message}))
    @$("#messages-list")[mode]($message)
    @scrollMessageList()

  scrollMessageList: ()->
    @$("#messages-list").scrollTop 1000000000

  sendMessage: ()->
    $messageBox = @$("#chat-message-box")
    messageText = _.str.trim $messageBox.val()
    if messageText.length
      @socket.emit "add-message", {room: @room, username: @user.get("username"), message: messageText}
      $messageBox.val ""

  onMessageTyping: (ev)=>
    if ev.keyCode is 13
      ev.preventDefault()
      @sendMessage()

  onSendClick: (ev)=>
    ev.preventDefault()
    @sendMessage()
