(function() {
  var CryptoWallet, DogeWallet, dogecoin, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("./crypto_wallet");

  dogecoin = require("node-dogecoin");

  DogeWallet = (function(_super) {
    __extends(DogeWallet, _super);

    function DogeWallet() {
      return DogeWallet.__super__.constructor.apply(this, arguments);
    }

    DogeWallet.prototype.currency = "DOGE";

    DogeWallet.prototype.createClient = function(options) {
      return this.client = dogecoin(options.client);
    };

    return DogeWallet;

  })(CryptoWallet);

  exports = module.exports = DogeWallet;

}).call(this);
