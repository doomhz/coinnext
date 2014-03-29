(function() {
  var DogeWallet, exports, trTime, transactionData;

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

  DogeWallet = (function() {
    function DogeWallet() {}

    DogeWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    DogeWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    DogeWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    DogeWallet.prototype.sendToAddress = function(address, account, amount, callback) {
      return callback(null, "unique_tx_id");
    };

    return DogeWallet;

  })();

  exports = module.exports = DogeWallet;

}).call(this);
