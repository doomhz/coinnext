(function() {
  var MethWallet, exports, trTime, transactionData;

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

  MethWallet = (function() {
    function MethWallet() {}

    MethWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    MethWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    MethWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    MethWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return MethWallet;

  })();

  exports = module.exports = MethWallet;

}).call(this);
