(function() {
  var CryptoWallet, NmcWallet, exports, namecoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  namecoin = require("namecoin");

  NmcWallet = (function(_super) {
    __extends(NmcWallet, _super);

    function NmcWallet() {
      return NmcWallet.__super__.constructor.apply(this, arguments);
    }

    NmcWallet.prototype.currency = "NMC";

    NmcWallet.prototype.initialCurrency = "NMC";

    NmcWallet.prototype.currencyName = "Namecoin";

    NmcWallet.prototype.createClient = function(options) {
      NmcWallet.__super__.createClient.call(this, options);
      return this.client = new namecoin.Client(options.client);
    };

    return NmcWallet;

  })(CryptoWallet);

  exports = module.exports = NmcWallet;

}).call(this);
