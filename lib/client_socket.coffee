redis = require "redis"

class ClientSocket

  namespace: "users"

  pub: null

  constructor: (options = {})->
    @namespace = options.namespace  if options.namespace
    @pub = redis.createClient options.redis.port, options.redis.host, {auth_pass: options.redis.pass}

  send: (data)->
    data.namespace = @namespace
    @pub.publish "external-events", JSON.stringify data

  close: ()->
    try
      @pub.quit()  if @pub
    catch e
      console.error "Could not close Pub connection #{@namespace}", e

exports = module.exports = ClientSocket