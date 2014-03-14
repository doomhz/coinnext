LocalStrategy = require('passport-local').Strategy
AdminUser = GLOBAL.db.AdminUser
strategyConfig =
  usernameField: "email"
  passwordField: "password"

passport.use new LocalStrategy strategyConfig, (email, password, done)->
  AdminUser.findByEmail email, (err, user)->
    return done(err) if err 
    return done(null, false, { message: 'Incorrect email.' }) if not user
    return done(null, false, { message: 'Incorrect password.' }) if not user.isValidPassword password
    return done(null, user)

passport.serializeUser (user, done)->
  done(null, user.id)

passport.deserializeUser (id, done)->
  AdminUser.findById id, done
