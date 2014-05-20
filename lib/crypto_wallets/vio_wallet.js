(function() {
  var CryptoWallet, VioWallet, coind, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  coind = require("node-coind");

  VioWallet = (function(_super) {
    __extends(VioWallet, _super);

    function VioWallet() {
      return VioWallet.__super__.constructor.apply(this, arguments);
    }

    VioWallet.prototype.currency = "VIO";

    VioWallet.prototype.initialCurrency = "VIO";

    VioWallet.prototype.currencyName = "Violincoin";

    VioWallet.prototype.createClient = function(options) {
      VioWallet.__super__.createClient.call(this, options);
      return this.client = new coind.Client(options.client);
    };

    return VioWallet;

  })(CryptoWallet);

  exports = module.exports = VioWallet;

}).call(this);
