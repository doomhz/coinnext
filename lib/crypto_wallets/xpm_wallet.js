(function() {
  var CryptoWallet, XpmWallet, exports, primecoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  primecoin = require("node-primecoin");

  XpmWallet = (function(_super) {
    __extends(XpmWallet, _super);

    function XpmWallet() {
      return XpmWallet.__super__.constructor.apply(this, arguments);
    }

    XpmWallet.prototype.currency = "XPM";

    XpmWallet.prototype.initialCurrency = "XPM";

    XpmWallet.prototype.currencyName = "Primecoin";

    XpmWallet.prototype.createClient = function(options) {
      XpmWallet.__super__.createClient.call(this, options);
      return this.client = new primecoin.Client(options.client);
    };

    return XpmWallet;

  })(CryptoWallet);

  exports = module.exports = XpmWallet;

}).call(this);
