(function() {
  var PpcWallet, exports, peercoin;

  peercoin = require("node-peercoin");

  PpcWallet = (function() {
    PpcWallet.prototype.configPath = "config.json";

    PpcWallet.prototype.address = null;

    PpcWallet.prototype.account = null;

    PpcWallet.prototype.confirmations = 1;

    PpcWallet.prototype.transactionFee = 0.0001;

    PpcWallet.prototype.balanceConfirmations = 0;

    PpcWallet.prototype.currency = "PPC";

    PpcWallet.prototype.convertionRates = {
      PPC_mPPC: 1000,
      mPPC_PPC: 0.001,
      PPC_PPC: 1,
      mPPC_mPPC: 1
    };

    function PpcWallet(options) {
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

    PpcWallet.prototype.createClient = function(options) {
      return this.client = new peercoin.Client(options.client);
    };

    PpcWallet.prototype.setupWallet = function(options) {
      this.account = options.wallet.account;
      return this.address = options.wallet.address;
    };

    PpcWallet.prototype.setupConfirmations = function(options) {
      this.confirmations = options.confirmations || this.confirmations;
      return this.balanceConfirmations = options.balance_confirmations || this.balanceConfirmations;
    };

    PpcWallet.prototype.setupTransactionFee = function(options) {
      this.transactionFee = options.transaction_fee || this.transactionFee;
      return this.client.setTxFee(this.transactionFee);
    };

    PpcWallet.prototype.setCurrency = function(currency) {
      return this.currency = currency || this.currency;
    };

    PpcWallet.prototype.generateAddress = function(account, callback) {
      return this.client.getNewAddress(account, callback);
    };

    PpcWallet.prototype.getBalance = function(account, callback) {
      var _this = this;
      return this.client.getBalance(account, this.balanceConfirmations, function(err, balance) {
        balance = _this.convert("PPC", _this.currency, balance);
        if (callback) {
          return callback(err, balance);
        }
      });
    };

    PpcWallet.prototype.chargeAccount = function(account, amount, callback) {
      var fromAccount, toAccount;
      amount = this.convert(this.currency, "PPC", amount);
      fromAccount = amount > 0 ? this.account : account;
      toAccount = amount > 0 ? account : this.account;
      amount = amount < 0 ? amount * -1 : amount;
      return this.client.move(fromAccount, toAccount, amount, callback);
    };

    PpcWallet.prototype.sendToAddress = function(address, fromAccount, amount, callback) {
      amount = this.convert(this.currency, "PPC", amount);
      return this.client.sendFrom(fromAccount, address, amount, this.confirmations, callback);
    };

    PpcWallet.prototype.convert = function(fromCurrency, toCurrency, amount) {
      return parseFloat(parseFloat(amount * this.convertionRates["" + fromCurrency + "_" + toCurrency]).toFixed(9));
    };

    PpcWallet.prototype.getInfo = function(callback) {
      return this.client.getInfo(callback);
    };

    PpcWallet.prototype.getAccounts = function(callback) {
      return this.client.listAccounts(callback);
    };

    PpcWallet.prototype.getTransactions = function(account, count, from, callback) {
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

    PpcWallet.prototype.getTransaction = function(txId, callback) {
      return this.client.getTransaction(txId, callback);
    };

    PpcWallet.prototype.getBankBalance = function(callback) {
      return this.getBalance(this.account, callback);
    };

    PpcWallet.prototype.loadOptionsFromFile = function() {
      var environment, fs, options;
      options = GLOBAL.appConfig();
      if (!options) {
        fs = require("fs");
        environment = process.env.NODE_ENV || "development";
        options = JSON.parse(fs.readFileSync("" + (process.cwd()) + "/" + this.configPath, "utf8"))[environment];
      }
      return options.wallets.ppc;
    };

    return PpcWallet;

  })();

  exports = module.exports = PpcWallet;

}).call(this);
