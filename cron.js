// Configure logger
if (process.env.NODE_ENV === "production") require("./configs/logger");

// Configure globals
GLOBAL.appConfig = require("./configs/config");

var fs = require("fs");
var request = require("request");
var CronJob = require("cron").CronJob;
var cronCurrencyPath = "./cron_dump/currency.dump";
var cronCurrencyExcludePath = "./cron_dump/currency_exclude.dump";
var excludedCurrencies = fs.readFileSync(cronCurrencyExcludePath).toString().split("\n");
var MarketHelper = require("./lib/market_helper");
var currencies = MarketHelper.getCurrencyTypes();
var transactionsInProgress = false;
var paymentsInProgress = false;
var tradeStatsInProgress = false;
var nextCurrencyIndex, nextCurrency;

var transactionsJob = new CronJob({
  cronTime: "*/3 * * * * *",
  onTick: function() {
    if (!transactionsInProgress) {
      transactionsInProgress = true;
      nextCurrency = fs.readFileSync(cronCurrencyPath).toString();
      if (excludedCurrencies.indexOf(nextCurrency) === -1) {
        var url = "http://" + GLOBAL.appConfig().wallets_host + "/load_latest_transactions/" + nextCurrency;
        var statusUrl = "http://" + GLOBAL.appConfig().wallets_host + "/wallet_health/" + nextCurrency;
        request.post(url, function (err, httpResponse, body) {
          if (err) {
            console.error(nextCurrency, "Error loading transactions.", err);
          } else {
            console.log(nextCurrency, body);
          }
          request.get(statusUrl, function (err, httpResponse, body) {
            if (err) {
              console.error(nextCurrency, "Error updating wallet status.", err);
            }
            nextCurrencyIndex = currencies.indexOf(nextCurrency);
            nextCurrencyIndex = currencies[nextCurrencyIndex + 1] ? nextCurrencyIndex + 1 : 0;
            nextCurrency = currencies[nextCurrencyIndex];
            fs.writeFileSync(cronCurrencyPath, nextCurrency);
            transactionsInProgress = false;
          });
        });
      } else {
        nextCurrencyIndex = currencies.indexOf(nextCurrency);
        nextCurrencyIndex = currencies[nextCurrencyIndex + 1] ? nextCurrencyIndex + 1 : 0;
        nextCurrency = currencies[nextCurrencyIndex];
        fs.writeFileSync(cronCurrencyPath, nextCurrency);
        transactionsInProgress = false;
      }
    }
  },
  start: false
});
transactionsJob.start();

var paymentsJob = new CronJob({
  cronTime: "0 */5 * * * *",
  onTick: function() {
    paymentsInProgress = true;
    var url = "http://" + GLOBAL.appConfig().wallets_host + "/process_pending_payments";
    request.post(url, function (err, httpResponse, body) {
      if (err) {
        console.error("Could not process payments.", err);
      } else {
        console.log("Processed payments: ", body);
      }
      paymentsInProgress = false;
    });
  },
  start: false
});
paymentsJob.start();

var tradeStatsJob = new CronJob({
  cronTime: "0 */30 * * * *",
  onTick: function() {
    tradeStatsInProgress = true;
    var url = "http://" + GLOBAL.appConfig().wallets_host + "/trade_stats";
    request.post(url, function (err, httpResponse, body) {
      if (err) {
        console.error("Could not aggregate trade stats.", err);
      } else {
        console.log("Trade stats: ", body);
      }
      tradeStatsInProgress = false;
    });
  },
  start: false
});
tradeStatsJob.start();

console.log("Processing jobs...");
