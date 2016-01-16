#!/usr/bin/env node
argv = require('minimist')(process.argv.slice(2));
config = {}
if(argv.c) {
  config = JSON.parse(require('fs').readFileSync(argv.c, 'utf8'));
}
pattern = new RegExp(config.pattern || "([^\\.]*)\\.?(.*)")
config.input = require('ttys').stdin
turtle = require('./index')(config);
if(process.argv.indexOf("-h") == -1) {
  process.stdin.pipe(require('split')()).on('data', function(line) {
    if(line) {
      turtle.start()
      tokens = line.split(' ')
      value = tokens[1] !== undefined ? tokens[1] : tokens[0]
      label = tokens[1] !== undefined ? tokens[0] : ""
      labelTokens = label.match(pattern)
      turtle.metric(labelTokens[1], labelTokens[2]).push(Number(value))
    }
  });
} else {
    process.stdout.write("Usage: turtle-race [-c config-file] [file]\n");
    process.exit(1);
}
