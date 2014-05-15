(function() {
  var CryptoWallet, MethWallet, cryptometh, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  cryptometh = require("node-cryptometh");

  MethWallet = (function(_super) {
    __extends(MethWallet, _super);

    function MethWallet() {
      return MethWallet.__super__.constructor.apply(this, arguments);
    }

    MethWallet.prototype.currency = "METH";

    MethWallet.prototype.initialCurrency = "METH";

    MethWallet.prototype.currencyName = "Cryptometh";

    MethWallet.prototype.createClient = function(options) {
      MethWallet.__super__.createClient.call(this, options);
      return this.client = new cryptometh.Client(options.client);
    };

    return MethWallet;

  })(CryptoWallet);

  exports = module.exports = MethWallet;

}).call(this);
