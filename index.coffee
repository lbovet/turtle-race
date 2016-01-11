blessed = require 'blessed'
zibar = require 'zibar'

msg = null
aggregators =
  last: (x) -> x[-1..][0]
  sum: (x) -> Array.prototype.slice.call(x).reduce (a, b) -> a + b
  avg: (x) -> aggregators.sum(x) / x.length
  max: (x) -> Math.max.apply(null, x)
  min: (x) -> Math.min.apply(null, x)
  count: (x) -> x.length
  growth: (x, context) ->
    value = aggregators.last(x)
    previous = if context.previous isnt undefined then context.previous else value
    diff = value - previous
    result = Math.max(diff,0)
    context.previous = value
    return result

turtle = (config) ->
  if config?.container
    screen = config.container.screen
    container = config.container
  else
    screen = blessed.screen
      smartCSR: true
    msg = blessed.box
      height: 3
      bottom: 0
      padding: 1
      parent: screen
    container = blessed.box
      padding: 1
      parent: screen
  colors = [ 'yellow', 'green', 'magenta', 'white']
  pos=0
  length=0
  scroll=pos
  series = {}
  styles = {}
  accumulators = {}
  contexts = {}
  t0 = Date.now()
  graphers = {}
  contents = []
  start = 0
  if config?.seconds
    format = (x) -> Math.ceil(x)
    interval = 5
  else
    format = (x) ->
      m = /(\d{2}:\d{2}:)(\d{2})/.exec new Date(x*1000).toTimeString()
      m[1].grey+m[2].cyan
    interval = 10
  refresh = ->
    for title,serie of series
      for subTitle,sub of serie
        graphers[title][subTitle] sub, styles[title]?[subTitle]
    screen.render()
  graphWidth=0
  layingOut=false
  layout = ->
    layingOut = true
    for content in contents
      content.destroy()
    contents.splice 0
    top = 0
    offset = 0
    titleWidth = 0
    graphCount = 0
    for title, serie of series
      titleWidth = Math.max title.length, titleWidth
      for subTitle of serie
        titleWidth = Math.max subTitle.length+1, titleWidth
        graphCount++
    container.height = screen.height - if msg then msg.height else 0
    maxGraphHeight = Math.floor(container.height / graphCount)
    graphHeight = Math.min maxGraphHeight, config?.maxGraphHeight || 8
    graphWidth = Math.max(container.width-titleWidth+1, 10)
    for title, serie of series
      lane = blessed.box
        parent: container
        width: '100%'
        height: graphHeight * Object.keys(serie).length
        top: top
      blessed.box
        tags: true
        parent: lane
        content: "{bold}{white-fg}#{title}"
      contents.push lane
      index = 0
      graphers[title] = {}
      for subTitle, sub of serie
        blessed.box
          tags: true
          parent: lane
          top: index * graphHeight+1
          content: " {white-fg}#{subTitle}"
        graph = blessed.box
          parent: lane
          top: index * graphHeight
          left: titleWidth
          height: graphHeight
          bottom: 1
        grapher = graphers[title][subTitle] = do (graph,index,subTitle) -> (s, style) ->
          length = graphWidth-10-interval
          if s.length <= length
            scroll = pos
          else
            scroll = pos if scroll >= pos - 1
          start = Math.max(scroll-length+1,0)
          s = s.slice start, start + Math.max(length, 0)
          style =
            marks: style?.marks?.slice start, start + Math.max(length, 0)
            colors: style?.colors?.slice start, start + Math.max(length, 0)
            vlines: style?.vlines?.slice start, start + Math.max(length, 0)
          factor = (Date.now()-t0)/1000/pos
          conf = config?.metrics?[subTitle]
          graph.setContent zibar s,
            color: conf?.color || colors[index % colors.length]
            height: conf?.height || graph.height-3
            yAxis: conf?.yAxis
            marks: style.marks
            colors: style.colors
            vlines: style.vlines
            min: conf?.min
            max: conf?.max
            high: conf?.high
            low: conf?.low
            xAxis:
              display: if conf?.xAxis?.display isnt undefined then conf?.xAxis?.display else true
              factor: factor
              color: conf?.xAxis?.color
              interval: conf?.xAxis?.interval || interval
              origin: start * factor + if not config?.seconds then t0/1000 + 6*factor else 0
              offset: -start - if not config?.seconds then 6 else 0
              format: conf?.xAxis?.format || format
        grapher sub, styles[title]?[subTitle]
        index++
        top += graphHeight
      screen.render()
      layingOut = false
  container.on 'resize', ->
    layout() if not layingOut
  layout()
  tryScroll = (s) ->
    if pos > length
      scroll = s
      refresh()
  container.key ['q', 'C-c'], ->
    process.exit()
  container.key 'left', -> tryScroll Math.max(length, scroll-10)
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
            contexts[title] = contexts[title] || {}
            context = contexts[title][subTitle] = contexts[title][subTitle] || {}
            last = series[title][subTitle][-1..]?[0] || 0
            if sub.length
              agg = config?.metrics?[subTitle]?.aggregator
              agg = aggregators[agg] if not agg?.apply
              agg = agg || aggregators.avg
              value = agg sub, context
            else
              value = if config?.keep then last else 0
            if not serie.length and pos > 1
              for i in [0..pos-1]
                serie.push 0
            serie.push value
            sub.splice 0
            layout() if not graphers[title]?[subTitle]
            graphers[title][subTitle] serie, styles[title]?[subTitle]
        screen.render()
      , config?.interval || 1000
    return api
  api.metric = (one, two) ->
    group = if two then one else ''
    name = if two then two else one
    accumulators[group] = accumulators[group] || {}
    acc = accumulators[group][name] = accumulators[group][name] || []
    styles[group] = styles[group] || {}
    style = styles[group][name] = styles[group][name] ||
      marks:  []
      colors: []
      vlines: []
    layout() if not graphers[group]?[name]
    result = {}
    result = do(acc, style) ->
      push: (value) ->
        acc.push value
        result
      mark: (value) ->
        style.marks[pos] = value
        result
      color: (value) ->
        style.colors[pos] = value
        result
      vline: (value) ->
        style.vlines[pos] = value
        result
  api.message = (line) ->
    msg.setContent line if msg
  api.start() if not config?.noAutoStart
  return api

module.exports = turtle

if process.argv[1].indexOf("turtle-race") != -1
  g = turtle
    keep: true
    seconds: true
    interval: 500
    metrics:
      cpu:
        max: 1
        aggregator: 'growth'
  p=0
  setInterval ->
    g.metric("one","cpu").push 123
  ,1000
  setTimeout ->
    g.metric("three","cpu").push Math.random()*6
  ,3000
  setInterval ->
    g.metric("two","io").push(Math.random()*6).vline("white,bold").mark("x").color("white,bold")
  ,1000
