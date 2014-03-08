LocalStrategy = require('passport-local').Strategy
User = GLOBAL.db.User
strategyConfig =
  usernameField: "email"
  passwordField: "password"

passport.use new LocalStrategy strategyConfig, (email, password, done)->
  User.findByEmail email, (err, user)->
    return done(err) if err 
    return done(null, false, { message: 'Incorrect email.' }) if not user
    return done(null, false, { message: 'Incorrect password.' }) if not user.isValidPassword password
    return done(null, user)

passport.serializeUser (user, done)->
  done(null, user.id)

passport.deserializeUser (id, done)->
  User.findById id, done
