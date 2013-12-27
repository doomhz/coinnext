(function() {
  var BtcWallet, bitcoin, exports;

  bitcoin = require("bitcoin");

  BtcWallet = (function() {
    BtcWallet.prototype.configPath = "config.json";

    BtcWallet.prototype.address = null;

    BtcWallet.prototype.account = null;

    BtcWallet.prototype.confirmations = 1;

    BtcWallet.prototype.transactionFee = 0.0001;

    BtcWallet.prototype.balanceConfirmations = 0;

    BtcWallet.prototype.currency = "BTC";

    BtcWallet.prototype.convertionRates = {
      BTC_mBTC: 1000,
      mBTC_BTC: 0.001,
      BTC_BTC: 1,
      mBTC_mBTC: 1
    };

    function BtcWallet(options) {
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

    BtcWallet.prototype.createClient = function(options) {
      return this.client = new bitcoin.Client(options.client);
    };

    BtcWallet.prototype.setupWallet = function(options) {
      this.account = options.wallet.account;
      return this.address = options.wallet.address;
    };

    BtcWallet.prototype.setupConfirmations = function(options) {
      this.confirmations = options.confirmations || this.confirmations;
      return this.balanceConfirmations = options.balance_confirmations || this.balanceConfirmations;
    };

    BtcWallet.prototype.setupTransactionFee = function(options) {
      this.transactionFee = options.transaction_fee || this.transactionFee;
      return this.client.setTxFee(this.transactionFee);
    };

    BtcWallet.prototype.setCurrency = function(currency) {
      return this.currency = currency || this.currency;
    };

    BtcWallet.prototype.generateAddress = function(account, callback) {
      return this.client.getNewAddress(account, callback);
    };

    BtcWallet.prototype.getBalance = function(account, callback) {
      var _this = this;
      return this.client.getBalance(account, this.balanceConfirmations, function(err, balance) {
        balance = _this.convert("BTC", _this.currency, balance);
        if (callback) {
          return callback(err, balance);
        }
      });
    };

    BtcWallet.prototype.chargeAccount = function(account, amount, callback) {
      var fromAccount, toAccount;
      amount = this.convert(this.currency, "BTC", amount);
      fromAccount = amount > 0 ? this.account : account;
      toAccount = amount > 0 ? account : this.account;
      amount = amount < 0 ? amount * -1 : amount;
      return this.client.move(fromAccount, toAccount, amount, callback);
    };

    BtcWallet.prototype.sendToAddress = function(address, fromAccount, amount, callback) {
      amount = this.convert(this.currency, "BTC", amount);
      return this.client.sendFrom(fromAccount, address, amount, this.confirmations, callback);
    };

    BtcWallet.prototype.convert = function(fromCurrency, toCurrency, amount) {
      return parseFloat(parseFloat(amount * this.convertionRates["" + fromCurrency + "_" + toCurrency]).toFixed(9));
    };

    BtcWallet.prototype.getInfo = function(callback) {
      return this.client.getInfo(callback);
    };

    BtcWallet.prototype.getAccounts = function(callback) {
      return this.client.listAccounts(callback);
    };

    BtcWallet.prototype.getTransactions = function(account, count, from, callback) {
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

    BtcWallet.prototype.getTransaction = function(txId, callback) {
      return this.client.getTransaction(txId, callback);
    };

    BtcWallet.prototype.getBankBalance = function(callback) {
      return this.getBalance(this.account, callback);
    };

    BtcWallet.prototype.loadOptionsFromFile = function() {
      var environment, fs, options;
      options = GLOBAL.appConfig();
      if (!options) {
        fs = require("fs");
        environment = process.env.NODE_ENV || "development";
        options = JSON.parse(fs.readFileSync("" + (process.cwd()) + "/" + this.configPath, "utf8"))[environment];
      }
      return options.wallets.btc;
    };

    return BtcWallet;

  })();

  exports = module.exports = BtcWallet;

}).call(this);
