(function() {
  var BtcWallet, exports, trTime, transactionData, transactionDetails, transactionsData, _;

  _ = require("underscore");

  trTime = Date.now() / 1000;

  transactionData = {
    amount: 1,
    txid: "unique_tx_id",
    confirmations: 6,
    time: trTime,
    details: []
  };

  transactionDetails = {
    account: "account",
    fee: 0.0001,
    address: "address",
    category: "receive"
  };

  transactionsData = {
    amount: 1,
    txid: "unique_tx_id",
    confirmations: 6,
    time: trTime,
    account: "account",
    fee: 0.0001,
    address: "address",
    category: "receive"
  };

  BtcWallet = (function() {
    function BtcWallet() {}

    BtcWallet.prototype.confirmations = 6;

    BtcWallet.prototype.getTransaction = function(txId, callback) {
      var tr;
      tr = _.clone(transactionData);
      tr.details = [_.clone(transactionDetails)];
      return callback(null, tr);
    };

    BtcWallet.prototype.getTransactions = function(account, limit, from, callback) {
      if (account == null) {
        account = "*";
      }
      if (limit == null) {
        limit = 100;
      }
      if (from == null) {
        from = 0;
      }
      return callback(null, [_.clone(transactionsData)]);
    };

    BtcWallet.prototype.getBalance = function(account, callback) {
      return callback(null, 1);
    };

    BtcWallet.prototype.chargeAccount = function(account, balance, callback) {
      return callback(null, true);
    };

    BtcWallet.prototype.sendToAddress = function(address, amount, callback) {
      return callback(null, "unique_tx_id_" + address);
    };

    BtcWallet.prototype.isBalanceConfirmed = function(existentConfirmations) {
      return existentConfirmations >= this.confirmations;
    };

    return BtcWallet;

  })();

  exports = module.exports = BtcWallet;

}).call(this);
