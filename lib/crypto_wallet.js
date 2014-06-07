(function() {
  var CryptoWallet, coind, exports;

  coind = require("node-coind");

  CryptoWallet = (function() {
    CryptoWallet.prototype.confirmations = null;

    CryptoWallet.prototype.address = null;

    CryptoWallet.prototype.account = null;

    CryptoWallet.prototype.passphrase = null;

    CryptoWallet.prototype.passphraseTimeout = 5;

    CryptoWallet.prototype.currency = null;

    CryptoWallet.prototype.initialCurrency = null;

    CryptoWallet.prototype.currencyName = null;

    CryptoWallet.prototype.convertionRates = {};

    function CryptoWallet(options) {
      if (!options) {
        options = this.loadOptions();
      }
      this.createClient(options);
      this.setupCurrency(options);
      this.setupConfirmations(options);
      this.setupWallet(options);
    }

    CryptoWallet.prototype.createClient = function(options) {
      if (options.client.sslCa) {
        options.client.sslCa = this.loadCertificate(options.client.sslCa);
      }
      return this.client = new coind.Client(options.client);
    };

    CryptoWallet.prototype.setupCurrency = function(options) {
      this.currency = options.currency;
      this.initialCurrency = options.initialCurrency || this.currency;
      return this.currencyName = options.currencyName;
    };

    CryptoWallet.prototype.setupConfirmations = function(options) {
      return this.confirmations = options.confirmations || this.confirmations;
    };

    CryptoWallet.prototype.setupWallet = function(options) {
      this.account = options.wallet.account;
      this.address = options.wallet.address;
      return this.passphrase = options.wallet.passphrase;
    };

    CryptoWallet.prototype.generateAddress = function(account, callback) {
      return this.submitPassphrase((function(_this) {
        return function(err) {
          if (err) {
            console.error(err);
          }
          return _this.client.getNewAddress(account, callback);
        };
      })(this));
    };

    CryptoWallet.prototype.sendToAddress = function(address, amount, callback) {
      amount = this.convert(this.currency, this.initialCurrency, amount);
      return this.submitPassphrase((function(_this) {
        return function(err) {
          if (err) {
            console.error(err);
          }
          return _this.client.sendToAddress(address, amount, callback);
        };
      })(this));
    };

    CryptoWallet.prototype.submitPassphrase = function(callback) {
      if (!this.passphrase) {
        return callback();
      }
      return this.client.walletPassphrase(this.passphrase, this.passphraseTimeout, callback);
    };

    CryptoWallet.prototype.convert = function(fromCurrency, toCurrency, amount) {
      var _ref;
      if ((_ref = this.convertionRates) != null ? _ref["" + fromCurrency + "_" + toCurrency] : void 0) {
        return parseFloat(parseFloat(amount * this.convertionRates["" + fromCurrency + "_" + toCurrency]).toFixed(8));
      }
      return parseFloat(parseFloat(amount).toFixed(8));
    };

    CryptoWallet.prototype.getInfo = function(callback) {
      return this.client.getInfo(callback);
    };

    CryptoWallet.prototype.getBlockCount = function(callback) {
      return this.client.getBlockCount(callback);
    };

    CryptoWallet.prototype.getBlockHash = function(blockIndex, callback) {
      return this.client.getBlockHash(blockIndex, callback);
    };

    CryptoWallet.prototype.getBlock = function(blockHash, callback) {
      return this.client.getBlock(blockHash, callback);
    };

    CryptoWallet.prototype.getBestBlockHash = function(callback) {
      return this.getBlockCount((function(_this) {
        return function(err, blockCount) {
          return _this.getBlockHash(blockCount - 1, callback);
        };
      })(this));
    };

    CryptoWallet.prototype.getBestBlock = function(callback) {
      return this.getBestBlockHash((function(_this) {
        return function(err, blockHash) {
          return _this.getBlock(blockHash, callback);
        };
      })(this));
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

    CryptoWallet.prototype.getBalance = function(account, callback) {
      return this.client.getBalance(account, (function(_this) {
        return function(err, balance) {
          balance = _this.convert(_this.initialCurrency, _this.currency, balance);
          if (callback) {
            return callback(err, balance);
          }
        };
      })(this));
    };

    CryptoWallet.prototype.getBankBalance = function(callback) {
      return this.getBalance("*", callback);
    };

    CryptoWallet.prototype.isBalanceConfirmed = function(existentConfirmations) {
      return existentConfirmations >= this.confirmations;
    };

    CryptoWallet.prototype.loadOptions = function() {
      return GLOBAL.appConfig().wallets[this.initialCurrency.toLowerCase()];
    };

    CryptoWallet.prototype.loadCertificate = function(path) {
      return require("fs").readFileSync("" + __dirname + "/../" + path);
    };

    return CryptoWallet;

  })();

  exports = module.exports = CryptoWallet;

}).call(this);
