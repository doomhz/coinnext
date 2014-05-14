(function() {
  var XpmWallet, exports, trTime, transactionData;

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

  XpmWallet = (function() {
    function XpmWallet() {}

    XpmWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    XpmWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    XpmWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    XpmWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return XpmWallet;

  })();

  exports = module.exports = XpmWallet;

}).call(this);
