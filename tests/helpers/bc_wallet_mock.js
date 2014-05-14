(function() {
  var BcWallet, exports, trTime, transactionData;

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

  BcWallet = (function() {
    function BcWallet() {}

    BcWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    BcWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    BcWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    BcWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return BcWallet;

  })();

  exports = module.exports = BcWallet;

}).call(this);
