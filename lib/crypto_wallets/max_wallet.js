(function() {
  var CryptoWallet, MaxWallet, exports, maxcoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  maxcoin = require("node-maxcoin");

  MaxWallet = (function(_super) {
    __extends(MaxWallet, _super);

    function MaxWallet() {
      return MaxWallet.__super__.constructor.apply(this, arguments);
    }

    MaxWallet.prototype.currency = "MAX";

    MaxWallet.prototype.initialCurrency = "MAX";

    MaxWallet.prototype.currencyName = "Maxcoin";

    MaxWallet.prototype.createClient = function(options) {
      MaxWallet.__super__.createClient.call(this, options);
      return this.client = new maxcoin.Client(options.client);
    };

    return MaxWallet;

  })(CryptoWallet);

  exports = module.exports = MaxWallet;

}).call(this);
