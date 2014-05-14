(function() {
  var CryptoWallet, DrkWallet, darkcoin, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  darkcoin = require("node-darkcoin");

  DrkWallet = (function(_super) {
    __extends(DrkWallet, _super);

    function DrkWallet() {
      return DrkWallet.__super__.constructor.apply(this, arguments);
    }

    DrkWallet.prototype.currency = "DRK";

    DrkWallet.prototype.initialCurrency = "DRK";

    DrkWallet.prototype.currencyName = "Darkcoin";

    DrkWallet.prototype.createClient = function(options) {
      DrkWallet.__super__.createClient.call(this, options);
      return this.client = new darkcoin.Client(options.client);
    };

    return DrkWallet;

  })(CryptoWallet);

  exports = module.exports = DrkWallet;

}).call(this);
