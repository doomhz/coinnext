(function() {
  var Chat, ChatSchema, exports;

  ChatSchema = new Schema({
    room: {
      type: String,
      index: true
    },
    username: {
      type: String,
      index: true
    },
    message: {
      type: String
    },
    created: {
      type: Date,
      "default": Date.now,
      index: true
    }
  });

  ChatSchema.set("autoIndex", false);

  ChatSchema.statics.findMessagesByRoom = function(room, callback) {
    var oneDayAgo;
    oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    return Chat.find({
      room: room,
      created: {
        $gt: oneDayAgo
      }
    }).sort({
      created: "desc"
    }).limit(10000).exec(callback);
  };

  Chat = mongoose.model("Chat", ChatSchema);

  exports = module.exports = Chat;

}).call(this);
