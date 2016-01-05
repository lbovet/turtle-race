blessed = require 'blessed'
babar = require 'babar'
style =
  bg: 'black'
screen = blessed.screen
  smartCSR: true
container = blessed.box
  padding: 1
  parent: screen
colors = [ 'green', 'cyan']
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
graphers = {}
adjust = (serie, length) ->
  if serie.length > length
    serie.splice 0, serie.length-length
  if serie.length < length
    serie.unshift [0,0] for i in [0..length-serie.length]
  return serie
layout = ->
  height = Math.floor(screen.height / (Object.keys(series).length))
  top = 0
  titleWidth = 0
  for title, serie of series
    titleWidth = Math.max title.length, titleWidth
    for subTitle of serie
      titleWidth = Math.max subTitle.length, titleWidth
  titleWidth += 2
  graphWidth = screen.width+1-titleWidth
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
      grapher = graphers[title][subTitle] = (serie) ->
        graph.setContent ""+serie
        graph.setContent babar(serie, {
          color: colors[index % colors.length],
          width: graphWidth
          height: graph.height
          yFractions: 1
        })
      grapher adjust sub, graphWidth-3
      index++
    top += height
  screen.render()
layout()
screen.on 'resize', ->
  layout()
