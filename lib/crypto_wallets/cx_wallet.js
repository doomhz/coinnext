(function() {
  var CryptoWallet, CxWallet, exports, xtracoin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  xtracoin = require("node-xtracoin");

  CxWallet = (function(_super) {
    __extends(CxWallet, _super);

    function CxWallet() {
      return CxWallet.__super__.constructor.apply(this, arguments);
    }

    CxWallet.prototype.currency = "CX";

    CxWallet.prototype.initialCurrency = "CX";

    CxWallet.prototype.currencyName = "Xtracoin";

    CxWallet.prototype.createClient = function(options) {
      CxWallet.__super__.createClient.call(this, options);
      return this.client = new xtracoin.Client(options.client);
    };

    return CxWallet;

  })(CryptoWallet);

  exports = module.exports = CxWallet;

}).call(this);
