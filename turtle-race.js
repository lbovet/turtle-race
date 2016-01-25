#!/usr/bin/env node
argv = require('minimist')(process.argv.slice(2));
config = {}
if(argv.c) {
  config = JSON.parse(require('fs').readFileSync(argv.c, 'utf8'));
}
pattern = new RegExp(config.pattern || "([^\\.]*)\\.?(.*)")
config.input = require('ttys').stdin
if(!process.stdin.isTTY) {
  turtle = require('./index')(config);
  process.stdin.pipe(require('split')()).on('data', function(line) {
    if(line) {
      turtle.start()
      tokens = line.split(' ')
      value = tokens[1] !== undefined ? tokens[1] : tokens[0]
      label = tokens[1] !== undefined ? tokens[0] : ""
      labelTokens = label.match(pattern)
      if(isNaN(value)) {
        if(value.length == 1) {
          turtle.metric(labelTokens[1], labelTokens[2]).mark(value);
        } else {
          if(value[0] == "|") {
            turtle.metric(labelTokens[1], labelTokens[2]).vline(value.split("|")[1]);
          } else {
            turtle.metric(labelTokens[1], labelTokens[2]).color(value);
          }
        }
      } else {
        turtle.metric(labelTokens[1], labelTokens[2]).push(Number(value));
      }
    }
  });
} else {
    process.stdout.write("Usage: <command> | turtle-race [-c config-file]\n");
    process.exit(1);
}
