(function() {
  var BtcWallet, CryptoWallet, bitcoin, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  bitcoin = require("bitcoin");

  BtcWallet = (function(_super) {
    __extends(BtcWallet, _super);

    function BtcWallet() {
      return BtcWallet.__super__.constructor.apply(this, arguments);
    }

    BtcWallet.prototype.currency = "BTC";

    BtcWallet.prototype.initialCurrency = "BTC";

    BtcWallet.prototype.currencyName = "Bitcoin";

    BtcWallet.prototype.createClient = function(options) {
      BtcWallet.__super__.createClient.call(this, options);
      return this.client = new bitcoin.Client(options.client);
    };

    return BtcWallet;

  })(CryptoWallet);

  exports = module.exports = BtcWallet;

}).call(this);
