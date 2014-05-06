request = require "request"

class CoreAPIClient

  host: null

  commands:
    "create_account": "post"
    "publish_order":  "post"
    "cancel_order":  "del"
    "create_payment": "post"
    "process_payment": "put"
    "cancel_payment": "del"
    "wallet_balance": "get"
    "wallet_info": "get"

  constructor: (options = {})->
    @host = options.host if options.host

  send: (command, data, callback = ()->)->
    url = "http://#{@host}/#{command}"
    for param in data
      url += "/#{param}"
    if @commands[command]
      try
        request[@commands[command]](url, {json: true}, callback)
      catch e
        console.error e
        callback "Bad response '#{e}'"
    else
      callback "Invalid command '#{command}'"

  sendWithData:  (command, data, callback = ()->)->
    uri = "http://#{@host}/#{command}"
    if @commands[command]
      options =
        uri: uri
        method: @commands[command]
        json: data
      try
        request options, callback
      catch e
        console.error e
        callback "Bad response #{e}"
    else
      callback "Invalid command '#{command}'"

exports = module.exports = CoreAPIClient