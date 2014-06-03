(function() {
  var LtcWallet, exports, trTime, transactionData;

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
        category: "receive"
      }
    ]
  };

  LtcWallet = (function() {
    function LtcWallet() {}

    LtcWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    LtcWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    LtcWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    LtcWallet.prototype.sendToAddress = function(address, account, amount, callback) {
      return callback(null, "unique_tx_id");
    };

    return LtcWallet;

  })();

  exports = module.exports = LtcWallet;

}).call(this);
