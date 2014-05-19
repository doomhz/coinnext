(function() {
  var TcoWallet, exports, trTime, transactionData;

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

  TcoWallet = (function() {
    function TcoWallet() {}

    TcoWallet.prototype.getTransaction = function(txId, callback) {
      return callback(null, transactionData);
    };

    TcoWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    TcoWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    TcoWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    return TcoWallet;

  })();

  exports = module.exports = TcoWallet;

}).call(this);
