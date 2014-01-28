ioClient = require "socket.io-client"

class ClientSocket

  host: "http://localhost:5000"

  path: "users"

  constructor: (options = {})->
    @host = options.host  if options.host
    @path = options.path  if options.path

  send: (data)->
    clientSocket = ioClient.connect("#{@host}/#{@path}")
    clientSocket.on "connect", (s)->
      clientSocket.emit "external-event", data
      clientSocket.socket.disconnect()

exports = module.exports = ClientSocket