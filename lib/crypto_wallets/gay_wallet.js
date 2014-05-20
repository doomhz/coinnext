(function() {
  var CryptoWallet, GayWallet, exports, homocoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  homocoin = require("node-homocoin");

  GayWallet = (function(_super) {
    __extends(GayWallet, _super);

    function GayWallet() {
      return GayWallet.__super__.constructor.apply(this, arguments);
    }

    GayWallet.prototype.currency = "GAY";

    GayWallet.prototype.initialCurrency = "GAY";

    GayWallet.prototype.currencyName = "Homocoin";

    GayWallet.prototype.createClient = function(options) {
      GayWallet.__super__.createClient.call(this, options);
      return this.client = new homocoin.Client(options.client);
    };

    return GayWallet;

  })(CryptoWallet);

  exports = module.exports = GayWallet;

}).call(this);
