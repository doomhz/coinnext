class App.TradeChartView extends App.MasterView

  collection: null

  initialize: (options = {})->

  render: ()->
    @collection.fetch
      success: ()=>
        @renderChart @collection.toJSON()

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
    @$el.highcharts "StockChart",
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
          gridLineColor: "#ecedef"
        }
        {
          gridLineWidth: 0
          opposite: true
        }
      ]
      xAxis:
        lineColor: "#ecedef"
        type: "time"
        dateTimeLabelFormats:
          millisecond: '%H:%M'
      tooltip:
        shared: true
        shadow: false
        backgroundColor: "#ffffff"
        borderColor: "#d1d5dd"
        formatter: ()->
          s = Highcharts.dateFormat('%b %e %Y %H:%M', this.x) + "<br />"
          s += "<b>Open:</b> " + _.str.toFixed(@points[1].point.open) + "<br />"
          s += "<b>High:</b> " + _.str.toFixed(@points[1].point.high) + "<br />"
          s += "<b>Low:</b> " + _.str.toFixed(@points[1].point.low) + "<br />"
          s += "<b>Close:</b> " + _.str.toFixed(@points[1].point.close) + "<br />"
          s += "<b>Volume:</b> " + _.str.toFixed(@points[0].point.y)            
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
