(function() {
  module.exports = function(sequelize, DataTypes) {
    var ACCEPTED_CATEGORIES, Transaction;
    ACCEPTED_CATEGORIES = ["send", "receive"];
    Transaction = sequelize.define("Transaction", {
      user_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: true
      },
      wallet_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: true
      },
      currency: {
        type: DataTypes.STRING,
        allowNull: false
      },
      account: {
        type: DataTypes.STRING
      },
      fee: {
        type: DataTypes.STRING
      },
      address: {
        type: DataTypes.STRING,
        allowNull: false
      },
      amount: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        allowNull: false
      },
      category: {
        type: DataTypes.STRING,
        allowNull: false
      },
      txid: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true
      },
      confirmations: {
        type: DataTypes.INTEGER,
        defaultValue: 0
      },
      balance_loaded: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
      }
    }, {
      underscored: true,
      tableName: "transactions",
      classMethods: {
        addFromWallet: function(transactionData, currency, wallet, callback) {
          var data, details, key;
          if (callback == null) {
            callback = function() {};
          }
          details = transactionData.details[0] || {};
          data = {
            user_id: (wallet ? wallet.user_id : void 0),
            wallet_id: (wallet ? wallet.id : void 0),
            currency: currency,
            account: details.account,
            fee: details.fee,
            address: details.address,
            category: details.category,
            amount: transactionData.amount,
            txid: transactionData.txid,
            confirmations: transactionData.confirmations,
            created_at: new Date(transactionData.time * 1000)
          };
          for (key in data) {
            if (!data[key] && data[key] !== 0) {
              delete data[key];
            }
          }
          return Transaction.findOrCreate({
            txid: data.txid
          }, data).complete(callback);
        },
        findPendingByUserAndWallet: function(userId, walletId, callback) {
          var query;
          query = {
            where: {
              user_id: userId,
              wallet_id: walletId,
              confirmations: {
                lt: 3
              }
            },
            order: [["created_at", "DESC"]]
          };
          return Transaction.findAll(query).complete(callback);
        },
        findProcessedByUserAndWallet: function(userId, walletId, callback) {
          var query;
          query = {
            where: {
              user_id: userId,
              wallet_id: walletId,
              confirmations: {
                gt: 2
              }
            },
            order: [["created_at", "DESC"]]
          };
          return Transaction.findAll(query).complete(callback);
        },
        findPendingByIds: function(ids, callback) {
          var query;
          if (ids.length === 0) {
            return callback(null, []);
          }
          query = {
            where: {
              txid: ids,
              confirmations: {
                lt: 3
              }
            },
            order: [["created_at", "DESC"]]
          };
          return Transaction.findAll(query).complete(callback);
        },
        isValidFormat: function(category) {
          return ACCEPTED_CATEGORIES.indexOf(category) > -1;
        },
        setUserById: function(txId, userId, callback) {
          return Transaction.update({
            user_id: userId
          }, {
            txid: txId
          }).complete(callback);
        },
        setUserAndWalletById: function(txId, userId, walletId, callback) {
          return Transaction.update({
            user_id: userId,
            wallet_id: walletId
          }, {
            txid: txId
          }).complete(callback);
        },
        markAsLoaded: function(id, callback) {
          return Transaction.update({
            balance_loaded: true
          }, {
            id: id
          }).complete(callback);
        }
      }
    });
    return Transaction;
  };

}).call(this);
