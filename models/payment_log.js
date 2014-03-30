(function() {
  module.exports = function(sequelize, DataTypes) {
    var PaymentLog;
    PaymentLog = sequelize.define("PaymentLog", {
      payment_id: {
        type: DataTypes.INTEGER.UNSIGNED,
        allowNull: false
      },
      log: {
        type: DataTypes.TEXT,
        set: function(response) {
          var e, log;
          try {
            log = typeof response === "string" ? response : "" + response;
            return this.setDataValue("log", log);
          } catch (_error) {
            e = _error;
            return this.setDataValue("log", response);
          }
        }
      }
    }, {
      tableName: "payment_logs",
      classMethods: {
        findById: function(id, callback) {
          return PaymentLog.find(id).complete(callback);
        },
        findByPaymentId: function(paymentId, callback) {
          var query;
          query = {
            where: {
              payment_id: paymentId
            }
          };
          return PaymentLog.findAll(query).complete(callback);
        }
      }
    });
    return PaymentLog;
  };

}).call(this);
