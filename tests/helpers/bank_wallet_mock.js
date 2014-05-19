(function() {
  var BankWallet, exports, trTime, transactionData;

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

  BankWallet = (function() {
    function BankWallet() {}

    BankWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    BankWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    BankWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    BankWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return BankWallet;

  })();

  exports = module.exports = BankWallet;

}).call(this);
