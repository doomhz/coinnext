(function() {
  var CryptoWallet, exports;

  CryptoWallet = (function() {
    CryptoWallet.prototype.configPath = "config.json";

    CryptoWallet.prototype.confirmations = 0;

    CryptoWallet.prototype.transactionFee = 0.0001;

    CryptoWallet.prototype.currency = null;

    function CryptoWallet(options) {
      if (options && options.configPath) {
        this.configPath = options.configPath;
      }
      if (!options) {
        options = this.loadOptionsFromFile();
      }
      this.createClient(options);
      this.setupConfirmations(options);
      this.setupTransactionFee(options);
    }

    CryptoWallet.prototype.createClient = function(options) {};

    CryptoWallet.prototype.setupConfirmations = function(options) {
      return this.confirmations = options.confirmations || this.confirmations;
    };

    CryptoWallet.prototype.setupTransactionFee = function(options) {
      this.transactionFee = options.transaction_fee || this.transactionFee;
      return this.client.setTxFee(this.transactionFee);
    };

    CryptoWallet.prototype.generateAddress = function(account, callback) {
      return this.client.getNewAddress(account, callback);
    };

    CryptoWallet.prototype.sendToAddress = function(address, amount, callback) {
      amount = this.parseAmount(amount);
      return this.client.sendToAddress(address, amount, callback);
    };

    CryptoWallet.prototype.parseAmount = function(amount) {
      return parseFloat(parseFloat(amount).toFixed(9));
    };

    CryptoWallet.prototype.getInfo = function(callback) {
      return this.client.getInfo(callback);
    };

    CryptoWallet.prototype.getTransactions = function(account, count, from, callback) {
      if (account == null) {
        account = "*";
      }
      if (count == null) {
        count = 10;
      }
      if (from == null) {
        from = 0;
      }
      return this.client.listTransactions(account, count, from, callback);
    };

    CryptoWallet.prototype.getTransaction = function(txId, callback) {
      return this.client.getTransaction(txId, callback);
    };

    CryptoWallet.prototype.getBankBalance = function(callback) {
      return this.client.cmd("getbalance", (function(_this) {
        return function(err, balance) {
          if (callback) {
            return callback(err, balance);
          }
        };
      })(this));
    };

    CryptoWallet.prototype.isBalanceConfirmed = function(existentConfirmations) {
      return existentConfirmations >= this.confirmations;
    };

    CryptoWallet.prototype.loadOptionsFromFile = function() {
      var environment, fs, options;
      options = GLOBAL.appConfig();
      if (!options) {
        fs = require("fs");
        environment = process.env.NODE_ENV || "development";
        options = JSON.parse(fs.readFileSync("" + (process.cwd()) + "/" + this.configPath, "utf8"))[environment];
      }
      return options.wallets[this.currency.toLowerCase()];
    };

    return CryptoWallet;

  })();

  exports = module.exports = CryptoWallet;

}).call(this);
