(function() {
  var CryptoWallet, PpcWallet, exports, peercoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("./crypto_wallet");

  peercoin = require("node-peercoin");

  PpcWallet = (function(_super) {
    __extends(PpcWallet, _super);

    function PpcWallet() {
      return PpcWallet.__super__.constructor.apply(this, arguments);
    }

    PpcWallet.prototype.currency = "PPC";

    PpcWallet.prototype.initialCurrency = "PPC";

    PpcWallet.prototype.currencyName = "Peercoin";

    PpcWallet.prototype.createClient = function(options) {
      return this.client = new peercoin.Client(options.client);
    };

    return PpcWallet;

  })(CryptoWallet);

  exports = module.exports = PpcWallet;

}).call(this);
