blessed = require 'blessed'
zibar = require 'zibar'
style =
  bg: 'black'
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
colors = [ 'yellow', 'blue,bold']
d = [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
pos=d.length
series =
  one:
    cpu: [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
    io: [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
  two:
    cpu: [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
    io: [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
  three:
    cpu: [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
    io: [1, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6, 5, 1, 6, 5, 5, 1, 6]
setInterval ->
  pos++
  for title,serie of series
    for subTitle,sub of serie
      sub.splice pos, 1, Math.ceil(Math.random() * 6)
      graphers[title][subTitle] adjust sub, pos
  screen.render()
, 400
graphers = {}
start = 0
adjust = (serie) ->
  length = Math.max(Math.floor(graphWidth * 0.9 - 5), 0)
  if serie.length < length
    last = if serie.length then serie[serie.length-1] else -1
    serie.push 0 for i in [last+1..last+length-serie.length]
  start = Math.max(pos-length+1,0)
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
    graphHeight = Math.floor(lane.height / (Object.keys(serie).length))
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
        #msg.setContent ""+s.length+" "+start+" "+pos+" "+(x for x in s)
        graph.setContent zibar s,
          color: colors[index % colors.length]
          height: graph.height-3
          xAxis:
            origin: start
            offset: -start
      grapher adjust sub
      index++
    top += height
  screen.render()
layout()
screen.on 'resize', ->
  layout()
