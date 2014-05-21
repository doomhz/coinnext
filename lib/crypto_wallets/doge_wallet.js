(function() {
  var CryptoWallet, DogeWallet, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CryptoWallet = require("../crypto_wallet");

  DogeWallet = (function(_super) {
    __extends(DogeWallet, _super);

    function DogeWallet() {
      return DogeWallet.__super__.constructor.apply(this, arguments);
    }

    DogeWallet.prototype.getBalance = function(account, callback) {
      return this.client.getBalance(account, (function(_this) {
        return function(err, balance) {
          balance = balance.result != null ? balance.result : balance;
          balance = _this.convert(_this.initialCurrency, _this.currency, balance);
          if (callback) {
            return callback(err, balance);
          }
        };
      })(this));
    };

    return DogeWallet;

  })(CryptoWallet);

  exports = module.exports = DogeWallet;

}).call(this);
