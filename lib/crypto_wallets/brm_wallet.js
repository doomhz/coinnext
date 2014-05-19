(function() {
  var BrmWallet, CryptoWallet, bitraam, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  bitraam = require("node-bitraam");

  BrmWallet = (function(_super) {
    __extends(BrmWallet, _super);

    function BrmWallet() {
      return BrmWallet.__super__.constructor.apply(this, arguments);
    }

    BrmWallet.prototype.currency = "BRM";

    BrmWallet.prototype.initialCurrency = "BRM";

    BrmWallet.prototype.currencyName = "Bitraam";

    BrmWallet.prototype.createClient = function(options) {
      BrmWallet.__super__.createClient.call(this, options);
      return this.client = new bitraam.Client(options.client);
    };

    return BrmWallet;

  })(CryptoWallet);

  exports = module.exports = BrmWallet;

}).call(this);
