blessed = require 'blessed'
zibar = require '../zibar'

aggregators =
  last: (x) -> x[-1..][0]
  sum: (x) -> Array.prototype.slice.call(x).reduce (a, b) -> a + b
  avg: (x) -> aggregators.sum(x) / x.length
  max: (x) -> Math.max.apply(null, x)
  min: (x) -> Math.min.apply(null, x)
  count: (x) -> x.length

garafa = (config) ->
  if config?.container
    screen = config.container.screen
    container = config.container
  else
    screen = blessed.screen
      smartCSR: true
    container = blessed.box
      padding: 1
      parent: screen
  msg = blessed.box
    height: 4
    bottom: 0
    padding: 0
    parent: screen
  colors = [ 'yellow', 'blue,bold', 'green', 'white,bold']
  pos=0
  scroll=pos
  m = ''
  series = {}
  accumulators = {}
  t0 = Date.now()
  graphers = {}
  start = 0
  length=0
  if config?.seconds
    format = (x) -> Math.ceil(x)
  else
    format = (x) ->
      m = /(\d{2}:\d{2}:)(\d{2})/.exec new Date(x*1000).toTimeString()
      m[1].grey+m[2].cyan
    interval = 10
  refresh = ->
    for title,serie of series
      for subTitle,sub of serie
        graphers[title][subTitle] adjust sub
    screen.render()
  adjust = (serie) ->
    length = Math.max(Math.floor(graphWidth * 0.9 - 5), 0)
    if serie.length < length
      scroll = pos
    else
      scroll = pos if scroll >= pos - 1
    start = Math.max(scroll-length+1,0)
    msg.setContent start + " " + interval
    return serie.slice start, start + length
  graphWidth=0
  layout = ->
    height = Math.floor(container.height / (Object.keys(series).length))-1
    top = 0
    offset = 0
    titleWidth = 0
    for title, serie of series
      titleWidth = Math.max title.length, titleWidth
      for subTitle of serie
        titleWidth = 1+Math.max subTitle.length, titleWidth
    graphWidth = Math.max(container.width+1-titleWidth, 10)
    for title, serie of series
        lane = blessed.box
          parent: container
          width: '100%'
          height: height
          top: top
        blessed.box
          tags: true
          parent: lane
          content: "{bold}{white-fg}#{title}"
        graphHeight = Math.max(Math.floor(lane.height / (Object.keys(serie).length)), 4)
        graphHeight = Math.min graphHeight, config?.maxGraphHeight || 8
        index = 0
        graphers[title] = {}
        for subTitle, sub of serie
            blessed.box
              tags: true
              parent: lane
              top: Math.ceil((index+0.2) * graphHeight)
              content: " {white-fg}#{subTitle}"
            graph = blessed.box
              parent: lane
              top: index * graphHeight
              left: titleWidth
              height: graphHeight
              bottom: 1
            grapher = graphers[title][subTitle] = do (graph,index) -> (s) ->
              factor = (Date.now()-t0)/1000/pos
              conf = config?.metrics?[subTitle]
              graph.setContent zibar s,
                color: colors[index % colors.length]
                height: conf?.height || graph.height-3
                yAxis: conf?.yAxis
                xAxis:
                  display: if conf?.xAxis?.display isnt undefined then conf?.xAxis?.display else true
                  factor: factor
                  color: conf?.xAxis?.color
                  interval: conf?.xAxis?.interval || interval
                  origin: start * factor + if not config?.seconds then t0/1000 + 6*factor else 0
                  offset: -start - if not config?.seconds then 6 else 0
                  format: conf?.xAxis?.format || format
            grapher adjust sub
            index++
        top += height
    screen.render()
  container.on 'resize', ->
    layout()
  layout()
  tryScroll = (s) ->
    if pos > length
      scroll = s
      refresh()
  container.key ['q', 'C-c'], ->
    process.exit()
  container.key 'left', -> tryScroll Math.max(length-1, scroll-10)
  container.key 'right', -> tryScroll scroll+10
  container.key 'home', -> tryScroll length-1
  container.key 'end', -> tryScroll pos
  api = {}
  api.start = ->
    setInterval ->
        pos++
        for title,acc of accumulators
          for subTitle,sub of acc
            series[title] = series[title] || {}
            serie = series[title][subTitle] = series[title][subTitle] || []
            last = series[title][subTitle][-1..] || 0
            if sub.length
              agg = config?.metrics?[subTitle]?.aggregator
              agg = aggregators[agg] if not agg?.apply
              agg = agg || aggregators.avg
              value = agg sub, last
            else
              value = if config?.keep then last else 0
            if not serie.length
              for i in [0..pos]
                serie.push 0
            serie.push value
            sub.splice 0
            layout() if not graphers[title]?[subTitle]
            graphers[title][subTitle] adjust serie
        screen.render()
      , config?.interval || 1000
    return api
  api.metric = (one, two) ->
    group = if two then one else ''
    name = if two then two else one
    accumulators[group] = accumulators[group] || {}
    acc = accumulators[group][name] = accumulators[group][name] || []
    layout() if not graphers[group]?[name]
    return {
      push: (value) -> acc.push value
    }
  api.start() if not config?.noAutoStart
  return api

module.exports = garafa

if process.argv[1].indexOf("garafa") != -1
  g = garafa
    keep: true
    seconds: true
    interval: 1000

setInterval ->
  g.metric("one","cpu").push Math.random()*6
,100

setInterval ->
  null
  g.metric("one","io").push Math.random()*6
,3000
