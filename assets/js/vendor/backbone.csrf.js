Backbone.sync = (function(original) {
  return function(method, model, options) {
    options.beforeSend = function(xhr) {
      xhr.setRequestHeader('X-CSRF-Token', CONFIG.csrf);
    };
   original(method, model, options);
  };
})(Backbone.sync);