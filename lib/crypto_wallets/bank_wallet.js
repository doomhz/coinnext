(function() {
  var BankWallet, CryptoWallet, bankcoin, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  bankcoin = require("node-bankcoin");

  BankWallet = (function(_super) {
    __extends(BankWallet, _super);

    function BankWallet() {
      return BankWallet.__super__.constructor.apply(this, arguments);
    }

    BankWallet.prototype.currency = "BANK";

    BankWallet.prototype.initialCurrency = "BANK";

    BankWallet.prototype.currencyName = "Bankcoin";

    BankWallet.prototype.createClient = function(options) {
      BankWallet.__super__.createClient.call(this, options);
      return this.client = new bankcoin.Client(options.client);
    };

    return BankWallet;

  })(CryptoWallet);

  exports = module.exports = BankWallet;

}).call(this);
