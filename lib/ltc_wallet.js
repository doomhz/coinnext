(function() {
  var LtcWallet, exports, litecoin;

  litecoin = require("litecoin");

  LtcWallet = (function() {
    LtcWallet.prototype.configPath = "config.json";

    LtcWallet.prototype.address = null;

    LtcWallet.prototype.account = null;

    LtcWallet.prototype.confirmations = 1;

    LtcWallet.prototype.transactionFee = 0.0001;

    LtcWallet.prototype.balanceConfirmations = 0;

    LtcWallet.prototype.currency = "LTC";

    LtcWallet.prototype.convertionRates = {
      LTC_mLTC: 1000,
      mLTC_LTC: 0.001,
      LTC_LTC: 1,
      mLTC_mLTC: 1
    };

    function LtcWallet(options) {
      if (options && options.configPath) {
        this.configPath = options.configPath;
      }
      if (!options) {
        options = this.loadOptionsFromFile();
      }
      this.createClient(options);
      this.setupWallet(options);
      this.setupConfirmations(options);
      this.setupTransactionFee(options);
      this.setCurrency(options.currency);
    }

    LtcWallet.prototype.createClient = function(options) {
      return this.client = new litecoin.Client(options.client);
    };

    LtcWallet.prototype.setupWallet = function(options) {
      this.account = options.wallet.account;
      return this.address = options.wallet.address;
    };

    LtcWallet.prototype.setupConfirmations = function(options) {
      this.confirmations = options.confirmations || this.confirmations;
      return this.balanceConfirmations = options.balance_confirmations || this.balanceConfirmations;
    };

    LtcWallet.prototype.setupTransactionFee = function(options) {
      this.transactionFee = options.transaction_fee || this.transactionFee;
      return this.client.setTxFee(this.transactionFee);
    };

    LtcWallet.prototype.setCurrency = function(currency) {
      return this.currency = currency || this.currency;
    };

    LtcWallet.prototype.generateAddress = function(account, callback) {
      return this.client.getNewAddress(account, callback);
    };

    LtcWallet.prototype.getBalance = function(account, callback) {
      return this.client.getBalance(account, this.balanceConfirmations, (function(_this) {
        return function(err, balance) {
          balance = _this.convert("LTC", _this.currency, balance);
          if (callback) {
            return callback(err, balance);
          }
        };
      })(this));
    };

    LtcWallet.prototype.chargeAccount = function(account, amount, callback) {
      var fromAccount, toAccount;
      amount = this.convert(this.currency, "LTC", amount);
      fromAccount = amount > 0 ? this.account : account;
      toAccount = amount > 0 ? account : this.account;
      amount = amount < 0 ? amount * -1 : amount;
      return this.client.move(fromAccount, toAccount, amount, callback);
    };

    LtcWallet.prototype.sendToAddress = function(address, fromAccount, amount, callback) {
      amount = this.convert(this.currency, "LTC", amount);
      if (fromAccount) {
        return this.client.sendFrom(fromAccount, address, amount, this.confirmations, callback);
      } else {
        return this.client.sendToAddress(address, amount, callback);
      }
    };

    LtcWallet.prototype.convert = function(fromCurrency, toCurrency, amount) {
      return parseFloat(parseFloat(amount * this.convertionRates["" + fromCurrency + "_" + toCurrency]).toFixed(9));
    };

    LtcWallet.prototype.getInfo = function(callback) {
      return this.client.getInfo(callback);
    };

    LtcWallet.prototype.getAccounts = function(callback) {
      return this.client.listAccounts(callback);
    };

    LtcWallet.prototype.getTransactions = function(account, count, from, callback) {
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

    LtcWallet.prototype.getTransaction = function(txId, callback) {
      return this.client.getTransaction(txId, callback);
    };

    LtcWallet.prototype.getBankBalance = function(callback) {
      return this.getBalance(this.account, callback);
    };

    LtcWallet.prototype.loadOptionsFromFile = function() {
      var environment, fs, options;
      options = GLOBAL.appConfig();
      if (!options) {
        fs = require("fs");
        environment = process.env.NODE_ENV || "development";
        options = JSON.parse(fs.readFileSync("" + (process.cwd()) + "/" + this.configPath, "utf8"))[environment];
      }
      return options.wallets.ltc;
    };

    return LtcWallet;

  })();

  exports = module.exports = LtcWallet;

}).call(this);
