(function() {
  var AdminUser, LocalStrategy, strategyConfig;

  LocalStrategy = require('passport-local').Strategy;

  AdminUser = GLOBAL.db.AdminUser;

  strategyConfig = {
    usernameField: "email",
    passwordField: "password"
  };

  passport.use(new LocalStrategy(strategyConfig, function(email, password, done) {
    return AdminUser.findByEmail(email, function(err, user) {
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
    return AdminUser.findById(id, done);
  });

}).call(this);
