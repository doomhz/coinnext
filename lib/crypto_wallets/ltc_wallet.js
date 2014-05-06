(function() {
  var CryptoWallet, LtcWallet, exports, litecoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  litecoin = require("litecoin");

  LtcWallet = (function(_super) {
    __extends(LtcWallet, _super);

    function LtcWallet() {
      return LtcWallet.__super__.constructor.apply(this, arguments);
    }

    LtcWallet.prototype.currency = "LTC";

    LtcWallet.prototype.initialCurrency = "LTC";

    LtcWallet.prototype.currencyName = "Litecoin";

    LtcWallet.prototype.createClient = function(options) {
      LtcWallet.__super__.createClient.call(this, options);
      return this.client = new litecoin.Client(options.client);
    };

    return LtcWallet;

  })(CryptoWallet);

  exports = module.exports = LtcWallet;

}).call(this);
