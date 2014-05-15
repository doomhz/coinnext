(function() {
  var VtcWallet, exports, trTime, transactionData;

  trTime = Date.now() / 1000;

  transactionData = {
    amount: 1,
    txid: "unique_tx_id",
    confirmations: 6,
    time: trTime,
    details: [
      {
        account: "account",
        fee: 0.0001,
        address: "address",
        category: "send"
      }
    ]
  };

  VtcWallet = (function() {
    function VtcWallet() {}

    VtcWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    VtcWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    VtcWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    VtcWallet.prototype.sendToAddress = function(address, account, amount, callback) {
      return callback(null, "unique_tx_id");
    };

    return VtcWallet;

  })();

  exports = module.exports = VtcWallet;

}).call(this);
