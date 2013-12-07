JsonRenderer =

  user: (user)->
    id:      user.id
    email:   user.email
    created: user.created

exports = module.exports = JsonRenderer