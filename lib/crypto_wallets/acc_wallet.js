(function() {
  var AccWallet, CryptoWallet, coind, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  coind = require("node-coind");

  AccWallet = (function(_super) {
    __extends(AccWallet, _super);

    function AccWallet() {
      return AccWallet.__super__.constructor.apply(this, arguments);
    }

    AccWallet.prototype.currency = "ACC";

    AccWallet.prototype.initialCurrency = "ACC";

    AccWallet.prototype.currencyName = "Antarcticcoin";

    AccWallet.prototype.createClient = function(options) {
      AccWallet.__super__.createClient.call(this, options);
      return this.client = new coind.Client(options.client);
    };

    return AccWallet;

  })(CryptoWallet);

  exports = module.exports = AccWallet;

}).call(this);
