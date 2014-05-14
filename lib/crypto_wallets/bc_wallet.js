(function() {
  var BcWallet, CryptoWallet, blackcoin, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  blackcoin = require("node-blackcoin");

  BcWallet = (function(_super) {
    __extends(BcWallet, _super);

    function BcWallet() {
      return BcWallet.__super__.constructor.apply(this, arguments);
    }

    BcWallet.prototype.currency = "BC";

    BcWallet.prototype.initialCurrency = "BC";

    BcWallet.prototype.currencyName = "Blackcoin";

    BcWallet.prototype.createClient = function(options) {
      BcWallet.__super__.createClient.call(this, options);
      return this.client = new blackcoin.Client(options.client);
    };

    return BcWallet;

  })(CryptoWallet);

  exports = module.exports = BcWallet;

}).call(this);
