(function() {
  var LocalStrategy, User, strategyConfig;

  LocalStrategy = require('passport-local').Strategy;

  User = GLOBAL.db.User;

  strategyConfig = {
    usernameField: "email",
    passwordField: "password",
    passReqToCallback: false
  };

  passport.use("local", new LocalStrategy(strategyConfig, function(email, password, done) {
    return User.findByEmail(email, function(err, user) {
      if (err) {
        return done(err);
      }
      if (!user) {
        return done(null, false, {
          message: 'Incorrect email.'
        });
      }
      if (!user.isValidPassword(password)) {
        return done(null, false, {
          message: 'Incorrect password.'
        });
      }
      return done(null, user);
    });
  }));

  passport.serializeUser(function(user, done) {
    return done(null, user.id);
  });

  passport.deserializeUser(function(id, done) {
    return User.findById(id, done);
  });

}).call(this);
