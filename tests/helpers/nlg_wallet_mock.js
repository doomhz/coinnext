(function() {
  var NlgWallet, exports, trTime, transactionData;

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

  NlgWallet = (function() {
    function NlgWallet() {}

    NlgWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    NlgWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    NlgWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    NlgWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return NlgWallet;

  })();

  exports = module.exports = NlgWallet;

}).call(this);
