#!/usr/bin/env node
argv = require('minimist')(process.argv.slice(2));
config = {}
if(argv.c) {
  config = JSON.parse(require('fs').readFileSync(argv.c, 'utf8'));
}
pattern = new RegExp(config.pattern or "([^\\.]*\\.)?"
turtle = require('./index')(config);
if(argv._[0] == '-') {
  process.stdin.pipe(require('split')())
    .on('data', function(line) {
      turtle.start()
      tokens = line.split(' ')
      value = if tokens[1] isnt undefined then tokens[1] else tokens[0]
      label = if tokens[1] isnt undefined then tokens[0] else ""
      labelTokens = tokens[1].split(".")
      turtle.metric line.split
    })
} else {
    process.stdout.write("Usage: zibar [-c config-file] [ - ] [ value1 [value2..]]\n");
    process.exit(1);
}
