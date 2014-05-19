(function() {
  var CryptoWallet, TcoWallet, exports, tacocoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  tacocoin = require("node-tacocoin");

  TcoWallet = (function(_super) {
    __extends(TcoWallet, _super);

    function TcoWallet() {
      return TcoWallet.__super__.constructor.apply(this, arguments);
    }

    TcoWallet.prototype.currency = "TCO";

    TcoWallet.prototype.initialCurrency = "TCO";

    TcoWallet.prototype.currencyName = "Tacocoin";

    TcoWallet.prototype.createClient = function(options) {
      TcoWallet.__super__.createClient.call(this, options);
      return this.client = new tacocoin.Client(options.client);
    };

    return TcoWallet;

  })(CryptoWallet);

  exports = module.exports = TcoWallet;

}).call(this);
