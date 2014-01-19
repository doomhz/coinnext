window.App or= {}

class App.UserModel extends Backbone.Model

  urlRoot: "/user"

  listenToEvents: ()->
    @fetch
      success: ()=>
        if @id
          @socket = io.connect("#{CONFIG.users.hostname}/users")
          @socket.on "connect", ()=>
            @socket.emit "listen", {id: @id}
          @socket.on "new-balance", (data)=>
            $.publish "new-balance", data
          @socket.on "new-order", (data)=>
            $.publish "new-order", data
