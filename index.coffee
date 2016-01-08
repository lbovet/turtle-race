blessed = require 'blessed'
zibar = require 'zibar'
garafa = (config) ->
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
  colors = config?.colors || [ 'yellow', 'blue,bold', 'green', 'white,bold']
  d = [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
  pos=0
  scroll=pos
  m = ''
  series =
    one:
      cpu: []
      io: []
    two:
      cpu: []
      io: []
    three:
      cpu: []
      io: []
  now = Math.round(Date.now()/1000)
  setInterval ->
    pos++
    for title,serie of series
      for subTitle,sub of serie
        sub.splice pos, 1, Math.ceil(Math.random() * 6)
        graphers[title][subTitle] adjust sub
    screen.render()
  , config?.delay || 1000
  graphers = {}
  start = 0
  length=0
  factor = if config?.delay then config.delay / 1000 else 1
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
    height = Math.floor(screen.height / (Object.keys(series).length))-1
    top = 0
    offset = 0
    titleWidth = 0
    for title, serie of series
      titleWidth = Math.max title.length, titleWidth
      for subTitle of serie
        titleWidth = Math.max subTitle.length, titleWidth
    graphWidth = Math.max(screen.width+1-titleWidth, 10)
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
      graphHeight = Math.min graphHeight, 8
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
          graph.setContent zibar s,
            color: colors[index % colors.length]
            height: graph.height-3
            xAxis:
              factor: if config?.delay then config.delay / 1000 else 1
              interval: interval
              origin: start * factor + if not config?.seconds then now + 6*factor else 0
              offset: -start - if not config?.seconds then 6 else 0
              format: format
        index++
      top += height
    screen.render()
  screen.on 'resize', ->
    layout()
  layout()
  tryScroll = (s) ->
    if pos > length
      scroll = s
      refresh()
  screen.key ['q', 'C-c'], ->
    process.exit()
  screen.key 'left', -> tryScroll Math.max(length-1, scroll-10)
  screen.key 'right', -> tryScroll scroll+10
  screen.key 'home', -> tryScroll length-1
  screen.key 'end', -> tryScroll pos
module.exports = garafa

if process.argv[1].indexOf("garafa") != -1
  garafa
    delay: 500
    seconds: true
