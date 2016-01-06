blessed = require 'blessed'
babar = require 'babar'
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
colors = [ 'green', 'cyan']
pos=4
series =
  one:
    cpu: [[0, 1], [1, 5], [2, 5], [3, 1], [4, 6]]
    io: [[0, 1], [1, 5], [2, 5], [3, 1], [4, 6]]
  two:
    cpu: [[0, 1], [1, 5], [2, 5], [3, 1], [4, 6]]
    io: [[0, 1], [1, 5], [2, 5], [3, 1], [4, 6]]
  three:
    cpu: [[0, 1], [1, 5], [2, 5], [3, 1], [4, 6]]
    io: [[0, 1], [1, 5], [2, 5], [3, 1], [4, 6]]
setInterval ->
  series.one.cpu.splice ++pos, 1, [pos, Math.ceil(Math.random() * 6)]
  graphers.one.cpu adjust series.one.cpu
  screen.render()
, 1000
graphers = {}
start = 0
adjust = (serie) ->
  length = Math.max(Math.floor(graphWidth * 0.9 - 5), 0)
  if serie.length < length
    last = if serie.length then serie[serie.length-1][0] else -1
    serie.push [i,0] for i in [last+1..last+length-serie.length]
  start = Math.max(pos-length+1,0)
  return serie.slice start, start + length
graphWidth=0
layout = ->
  height = Math.floor(screen.height / (Object.keys(series).length))-1
  top = 0
  titleWidth = 0
  for title, serie of series
    titleWidth = Math.max title.length, titleWidth
    for subTitle of serie
      titleWidth = Math.max subTitle.length, titleWidth
  titleWidth += 2
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
    graphHeight = Math.floor(lane.height / (Object.keys(serie).length))-1
    index = 0
    graphers[title] = {}
    for subTitle, sub of serie
      blessed.box
        tags: true
        parent: lane
        top: Math.ceil((index+0.5) * graphHeight)
        content: " {white-fg}#{subTitle}"
      graph = blessed.box
        parent: lane
        top: index * graphHeight + 1
        left: titleWidth
        height: graphHeight
        bottom: 1
      grapher = graphers[title][subTitle] = do (graph) -> (s) ->
        msg.setContent ""+s.length+" "+start+" "+pos+" "+(x[1] for x in s)
        graph.setContent babar s,
          color: colors[index % colors.length],
          width: graphWidth
          height: graph.height
          yFractions: 1
      grapher adjust sub
      index++
    top += height
  screen.render()
layout()
screen.on 'resize', ->
  layout()
