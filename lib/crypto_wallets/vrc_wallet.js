(function() {
  var CryptoWallet, VrcWallet, coind, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  coind = require("node-coind");

  VrcWallet = (function(_super) {
    __extends(VrcWallet, _super);

    function VrcWallet() {
      return VrcWallet.__super__.constructor.apply(this, arguments);
    }

    VrcWallet.prototype.currency = "VRC";

    VrcWallet.prototype.initialCurrency = "VRC";

    VrcWallet.prototype.currencyName = "Vericoin";

    VrcWallet.prototype.createClient = function(options) {
      VrcWallet.__super__.createClient.call(this, options);
      return this.client = new coind.Client(options.client);
    };

    return VrcWallet;

  })(CryptoWallet);

  exports = module.exports = VrcWallet;

}).call(this);
