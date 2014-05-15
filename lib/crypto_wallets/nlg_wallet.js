(function() {
  var CryptoWallet, NlgWallet, exports, guldencoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  guldencoin = require("node-guldencoin");

  NlgWallet = (function(_super) {
    __extends(NlgWallet, _super);

    function NlgWallet() {
      return NlgWallet.__super__.constructor.apply(this, arguments);
    }

    NlgWallet.prototype.currency = "NLG";

    NlgWallet.prototype.initialCurrency = "NLG";

    NlgWallet.prototype.currencyName = "Guldencoin";

    NlgWallet.prototype.createClient = function(options) {
      NlgWallet.__super__.createClient.call(this, options);
      return this.client = new guldencoin.Client(options.client);
    };

    return NlgWallet;

  })(CryptoWallet);

  exports = module.exports = NlgWallet;

}).call(this);
