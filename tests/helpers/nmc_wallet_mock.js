(function() {
  var NmcWallet, exports, trTime, transactionData;

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

  NmcWallet = (function() {
    function NmcWallet() {}

    NmcWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    NmcWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    NmcWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    NmcWallet.prototype.sendToAddress = function(address, account, amount, callback) {
      return callback(null, "unique_tx_id");
    };

    return NmcWallet;

  })();

  exports = module.exports = NmcWallet;

}).call(this);
