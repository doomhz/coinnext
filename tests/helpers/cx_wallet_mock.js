(function() {
  var CxWallet, exports, trTime, transactionData;

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

  CxWallet = (function() {
    function CxWallet() {}

    CxWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    CxWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    CxWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    CxWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return CxWallet;

  })();

  exports = module.exports = CxWallet;

}).call(this);
