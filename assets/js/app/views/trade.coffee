class App.TradeView extends App.MasterView

  model: null

  tpl: "coin-stats-tpl"

  currency1: null

  currency2: null

  tradeStats: null

  events:
    "click .market-switcher": "onMarketSwitch"
    "click .header-balance .amount": "onAmountClick"
    "submit .order-form": "onOrderSubmit"
    "keyup #buy-amount-input": "onBuyAmountChange"
    "keyup #sell-amount-input": "onSellAmountChange"

  initialize: (options = {})->
    @currency1 = options.currency1
    @currency2 = options.currency2
    @chartStats = new App.TradeStatsCollection null,
      type: "#{@currency1}_#{@currency2}"
    $.subscribe "market-stats-updated", @onMarketStatsUpdated

  render: ()->
    @model.fetch
      success: ()=>
        @renderTradeStats()
      error: ()=>

  renderTradeStats: ()->
    stats = @model.get "#{@currency1}_#{@currency2}"
    @$("#coin-stats").html @template
      coinStats: stats
      currency1: @currency1
      currency2: @currency2

  renderChartStats: ()->
    @chartStats.fetch
      success: ()=>
        @renderChart @chartStats.toJSON()

  renderChart: (data)->
    # split the data set into ohlc and volume
    ohlc = []
    volume = []
    xAxis = []
    dataLength = data.length
    i = 0
    while i < dataLength
      startTime = new Date(data[i].start_time).getTime()
      ohlc.push [
        startTime # the date
        data[i].open_price # open
        data[i].high_price # high
        data[i].low_price # low
        data[i].close_price # close
      ]
      volume.push [
        startTime # the date
        data[i].volume # the volume
      ]
      i++

    # create the chart
    @$("#trade-chart").highcharts "StockChart",
      rangeSelector:
        enabled: false
      scrollbar:
        enabled: false
      navigator:
        enabled: false

      exporting:
        buttons: [
          printButton:
            enabled: false
          exportButton:
            enabled: false
        ]
      credits:
        enabled: false

      yAxis: [
        {
          lineWidth: 0
        }
        {
          gridLineWidth: 0
          opposite: true
        }
      ]
      xAxis:
        type: "time"
        dateTimeLabelFormats:
          millisecond: '%H:%M'
      tooltip:
        shared: true
        shadow: false
        borderColor: "#d1d5dd"
        formatter: ()->
          s = "<b>"+Highcharts.dateFormat('%b %e %Y %H:%M', this.x) + "</b><br />"
          
          s += "<b>Open:</b> " + @points[1].point.open + "<br />"+"<b>High:</b> " + @points[1].point.high + "<br />"+"<b>Low:</b> " + @points[1].point.low + "<br />"+"<b>Close:</b> " + @points[1].point.close + "<br />"+"<b>Volume:</b> " + @points[0].point.y   
            
          return s
      series: [
        {
          type: "column"
          name: "Volume"
          data: volume
          yAxis: 1
          color: "#dddddd"
        }
        {
          type: "candlestick"
          name: "Price"
          data: ohlc
          yAxis: 0
          color: "#3eae5f"
          upColor: "#da4444"
          lineColor: "#3eae5f"
          upLineColor: "#da4444"
          borderWidth: 0
        }
      ]

  isValidAmount: (amount)->
    _.isNumber(amount) and not _.isNaN(amount) and amount > 0

  onMarketSwitch: (ev)->
    $target = $(ev.target)
    @$("#limit-#{$target.attr("name")}-box,#market-#{$target.attr("name")}-box").hide()
    @$("##{$target.val()}-#{$target.attr("name")}-box").show()

  onOrderSubmit: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    amount = parseFloat $form.find("[name='amount']").val()
    return $.publish "error", "Please submit a valid amount bigger than 0."  if not @isValidAmount amount
    order = new App.OrderModel
      type: $form.find("[name='type']").val()
      action: $form.find("[name='action']").val()
      sell_currency: $form.find("[name='sell_currency']").val()
      buy_currency: $form.find("[name='buy_currency']").val()
      amount: amount
      unit_price: $form.find("[name='unit_price']").val()
    order.save null,
      success: ()->
        $form.find("[name='amount']").val ""
      error: (m, xhr)->
        $.publish "error", xhr

  onAmountClick: (ev)->
    ev.preventDefault()
    $target = $(ev.target)
    $input = @$("##{$target.data('type')}-amount-input")
    $input.val($target.data('amount'))
    $input.trigger "keyup"

  onBuyAmountChange: (ev)->
    $target = $(ev.target)
    buyAmount = parseFloat $target.val()
    $result = @$("#buy-amount-result")
    if @isValidAmount buyAmount
      fee = parseFloat $result.data("fee")
      lastPrice = parseFloat @$("#market-buy-unit-price").val()
      total = _.str.roundToThree buyAmount * lastPrice - fee
      #console.log spendAmount, fee, lastPrice, total
      $result.text total
    else
      $result.text 0

  onSellAmountChange: (ev)->
    $target = $(ev.target)
    spendAmount = parseFloat $target.val()
    $result = @$("#sell-amount-result")
    if @isValidAmount spendAmount
      fee = parseFloat $result.data("fee")
      lastPrice = parseFloat @$("#market-sell-unit-price").val()
      total = _.str.roundToThree spendAmount * lastPrice - fee
      #console.log spendAmount, fee, lastPrice, total
      $result.text total
    else
      $result.text 0

  onMarketStatsUpdated: (ev, data)=>
    @render()
