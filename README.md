# Turtle Race
Real-time metric graphs in the terminal.

![anim](https://cloud.githubusercontent.com/assets/692124/12593996/2566ab4e-c474-11e5-8d24-bf0b5da0108f.gif)

# Installation
```
npm install turtle-race -g
```  
If you don't know what npm is, read [this](https://docs.npmjs.com/getting-started/installing-node).

# Usage
```
Usage: <command> | turtle-race [-c config-file]
```  

The `turtle-race` command reads metrics from the standard input. On line per value formatted as follows:

```
<name> <value>
```

Example:
```
(while true; do echo one $RANDOM; echo two $RANDOM; sleep 0.5; done) | turtle-race
```
![anim](https://cloud.githubusercontent.com/assets/692124/12594442/72240ff6-c476-11e5-88f1-8cc4630ba29b.gif)

## Keys

- Left/Right: scroll
- Home/End: scroll to start/end
- Ctrl-C or q: quit

## Configuration

```javascript
{
  "interval": 500,               // sampling period in ms (default: 1000)
  "seconds" : true,              // shows only number of seconds since start
  "keep": true,                  // keeps showing the last value
  "pattern": "([^-]*)-(.*)",     // pattern to parse the metric name (see metric groups below)
  "metrics": {                   // specific configuration for a given metric
    "<metric-name>": {           // the metric name (without group, see below)
      "aggregator": "growth",    // function aggregating values (see aggregators below)
      "color": "yellow,bold"     // [zibar configuration](https://www.npmjs.com/package/zibar#configuration)
    }
  }
}
```

## Metric Groups

Metrics can be grouped. By default, the group name prefixes the metric name, separated with a dot. So the metric line format is:

```
<group>.<name> <value>
```

When using a metric source with a different format, you can specify in the `pattern` configuration value the regular expression that will be used to parse the metric group and name. It should provide one or two capture groups, for the group name and the metric name.

## Aggregators

When multiples values are received during the sampling period, they are combined using an aggregator function.

- avg (default)
- last
- sum
- min
- max
- count

Additionally, for values that are only growing, like counters, it may be interesting to show only the difference in each sample. This is actually a non-zero derivative.

- growth

## Marking values

In addition to values, the input can contain zibar markers and styling for the current value. Example:

```
nginx.cpu red,bold       # styles the graph bar  
mysql.requests ▼         # place a mark above the graph
redis.memory |white      # draws a vertical line
```

![marking values](https://cloud.githubusercontent.com/assets/692124/12594246/6756e784-c475-11e5-8ae6-017969efb82c.png)

# Using as a library

```
npm install turtle-race --save
```

```javascript
var config = {
  seconds : true,
  interval: 500,
  keep: true,
  pattern: "[^-]*-(.*)",
  metrics: {
    one: {
      aggregator: "growth",
      color: "yellow,bold"
    }
  }
}

var turtle = require('turtle-race')(config);

turtle.metric("one").push(5.4);  // metric without group
turtle.metric("nginx", "cpu").push(5.4); // metric with group
turtle.metric("nginx", "cpu").push(5.4).color("red,bold"); // fluent api

var metric = turtle.metric("nginx", "cpu");
metric.push(5.4);
metric.mark("▼");  // marker above graph
metric.mark({ symbol:"▼", color: "yellow,bold" }); // styled marker
metric.vline("white"); // vertical line
```

## Auto-Start
By default, the rendering starts automatically. You can control it yourself with the config parameter `noAutoStart: true` then start it when appropriate.

```javascript
turtle.start();
```

## Status message
A message can be displayed in the bottom line.

```javascript
turtle.message("hello");
```

## Custom Aggregator Function

In the metric configuration, additionally to the named builtin aggregators, you can use a custom function. For example, an aggregator using the first value received during the sampling period.

```javascript
aggregator: function(values, context) { return values[0] }
```

The `context` parameter is an object associated to the metric. You can use it to store data you want to use across calls, e.g. to implement statistics windows.

## Blessed Integration
As turtle-race is based on [blessed](https://www.npmjs.com/package/blessed), you can embed it in an existing node by specifying it as `container` parameter in the config.
