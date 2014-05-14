(function() {
  var DrkWallet, exports, trTime, transactionData;

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

  DrkWallet = (function() {
    function DrkWallet() {}

    DrkWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    DrkWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    DrkWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    DrkWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return DrkWallet;

  })();

  exports = module.exports = DrkWallet;

}).call(this);
