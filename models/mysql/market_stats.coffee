module.exports = (sequelize, DataTypes) ->
  
  MARKETS = [
    "LTC_BTC", "PPC_BTC"
  ]

  MarketStats = sequelize.define "MarketStats",
      type:
        type: DataTypes.STRING
        allowNull: false
        unique: true
      label:
        type: DataTypes.STRING
        allowNull: false
        unique: true
      last_price:
        type: DataTypes.STRING
        defaultValue: 0
        allowNull: false
      day_high:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      day_low:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      volume1:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      volume2:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      growth_ratio:
        type: DataTypes.FLOAT
        defaultValue: 0
        allowNull: false
      today:
        type: DataTypes.DATE
    ,
      underscored: true
      tableName: "market_stats"
      classMethods:
        
        getStats: (callback = ()->)->
          MarketStats.findAll().complete (err, marketStats)->
            stats = {}
            for stat in marketStats
              stats[stat.type] = stat
            callback err, stats
        
        trackFromOrder: (order, callback = ()->)->
          type = if order.action is "buy" then "#{order.buy_currency}_#{order.sell_currency}" else "#{order.sell_currency}_#{order.buy_currency}"
          if order.action is "sell"
            MarketStats.find({where: {type: type}}).complete (err, marketStats)->
              marketStats.resetIfNotToday()
              marketStats.growth_ratio = MarketStats.calculateGrowthRatio marketStats.last_price, order.unit_price  if order.unit_price isnt marketStats.last_price
              marketStats.last_price = order.unit_price
              marketStats.day_high = order.unit_price  if order.unit_price > marketStats.day_high
              marketStats.day_low = order.unit_price  if order.unit_price < marketStats.day_low or marketStats.day_low is 0
              marketStats.volume1 += order.amount
              marketStats.volume2 += order.result_amount
              marketStats.save().complete callback

        getMarkets: ()->
          MARKETS

        isValidMarket: (action, buyCurrency, sellCurrency)->
          market = "#{buyCurrency}_#{sellCurrency}"  if action is "buy"
          market = "#{sellCurrency}_#{buyCurrency}"  if action is "sell"
          MarketStats.getMarkets().indexOf(market) > -1

        calculateGrowthRatio: (lastPrice, newPrice)->
          parseFloat newPrice * 100 / lastPrice - 100
      
      instanceMethods:
        
        resetIfNotToday: ()->
          today = new Date().getDate()
          if today isnt @today.getDate()
            @today = new Date()
            @day_high = 0
            @day_low = 0
            @volume1 = 0
            @volume2 = 0
  
  MarketStats