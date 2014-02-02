ioClient = require "socket.io-client"

class ClientSocket

  host: "http://localhost:5000"

  path: "users"

  constructor: (options = {})->
    @host = options.host  if options.host
    @path = options.path  if options.path

  send: (data)->
    if not @socket
      @socket = ioClient.connect("#{@host}/#{@path}")
      @socket.on "connect", (s)=>
        @socket.emit "external-event", data
        #socket.socket.disconnect()
    else
      @socket.emit "external-event", data

exports = module.exports = ClientSocket