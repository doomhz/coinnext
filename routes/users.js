(function() {
  var JsonRenderer, User;

  User = require('../models/user');

  JsonRenderer = require('../lib/json_renderer');

  module.exports = function(app) {
    var login;
    app.post("/user", function(req, res) {
      var user;
      user = new User({
        email: req.body.email,
        password: User.hashPassword(req.body.password)
      });
      return user.save(function(err) {
        if (err) {
          return JsonRenderer.error(err, res);
        }
        return res.json(JsonRenderer.user(user));
      });
    });
    app.post("/login", function(req, res, next) {
      return login(req, res, next);
    });
    app.put("/login", function(req, res, next) {
      return login(req, res, next);
    });
    app.get("/user/:id?", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res);
      }
      return res.json(JsonRenderer.user(req.user));
    });
    app.get("/logout", function(req, res) {
      req.logout();
      if (req.accepts("html")) {
        return res.redirect("/");
      } else {
        return res.json({});
      }
    });
    app.get("/generate_gauth", function(req, res) {
      if (!req.user) {
        return JsonRenderer.error(null, res);
      }
      return req.user.generateGAuthData(function() {
        return res.json(JsonRenderer.user(req.user));
      });
    });
    app.post("/user_event", function(req, res, next) {
      var data, e, eventType, sId, socket, userId, _ref;
      userId = req.body.user_id;
      eventType = req.body.type;
      data = req.body.data;
      if (GLOBAL.usersSocket) {
        try {
          _ref = GLOBAL.usersSocket.sockets;
          for (sId in _ref) {
            socket = _ref[sId];
            if (socket.user_id === userId) {
              socket.emit(eventType, data);
            }
          }
          return res.json({});
        } catch (_error) {
          e = _error;
          console.error("Could not emit to socket namespace /users " + userId + ": " + e);
          return JsonRenderer.error("Could not emit to socket namespace /users " + userId, res);
        }
      }
    });
    login = function(req, res, next) {
      return passport.authenticate("local", function(err, user, info) {
        if (err) {
          return JsonRenderer.error(err, res, 401);
        }
        if (!user) {
          return JsonRenderer.error("Invalid credentials", res, 401);
        }
        return req.logIn(user, function(err) {
          if (err) {
            return JsonRenderer.error("Invalid credentials", res, 401);
          }
          if (user.gauth_data && !user.isValidGAuthPass(req.body.gauth_pass)) {
            req.logout();
            return JsonRenderer.error("Invalid Google Authenticator code", res, 401);
          }
          return res.json(JsonRenderer.user(req.user));
        });
      })(req, res, next);
    };
    return GLOBAL.usersSocket = GLOBAL.io.of("/users").on("connection", function(socket) {
      return socket.on("listen", function(data) {
        return socket.user_id = data.id;
      });
    });
  };

}).call(this);
