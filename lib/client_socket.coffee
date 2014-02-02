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
    else
      @socket.emit "external-event", data

  close: ()->
    try
      @socket.socket.disconnect()  if @socket
    catch e
      console.error "Could not close client socket #{@path}", e

exports = module.exports = ClientSocket