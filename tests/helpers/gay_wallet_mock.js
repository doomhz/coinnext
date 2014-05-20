(function() {
  var GayWallet, exports, trTime, transactionData;

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

  GayWallet = (function() {
    function GayWallet() {}

    GayWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    GayWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    GayWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    GayWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return GayWallet;

  })();

  exports = module.exports = GayWallet;

}).call(this);
