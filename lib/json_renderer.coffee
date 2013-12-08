JsonRenderer =

  user: (user)->
    id:      user.id
    email:   user.email
    created: user.created
    gauth_data: user.gauth_data

exports = module.exports = JsonRenderer