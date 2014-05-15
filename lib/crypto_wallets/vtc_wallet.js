(function() {
  var CryptoWallet, VtcWallet, exports, vertcoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  vertcoin = require("node-vertcoin");

  VtcWallet = (function(_super) {
    __extends(VtcWallet, _super);

    function VtcWallet() {
      return VtcWallet.__super__.constructor.apply(this, arguments);
    }

    VtcWallet.prototype.currency = "VTC";

    VtcWallet.prototype.initialCurrency = "VTC";

    VtcWallet.prototype.currencyName = "Vertcoin";

    VtcWallet.prototype.createClient = function(options) {
      VtcWallet.__super__.createClient.call(this, options);
      return this.client = new vertcoin.Client(options.client);
    };

    return VtcWallet;

  })(CryptoWallet);

  exports = module.exports = VtcWallet;

}).call(this);
