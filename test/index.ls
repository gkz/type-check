type-check = require '..'
{strict-equal: equal} = require 'assert'

suite 'index' ->
  test 'version' ->
    equal type-check.VERSION, (require '../package.json').version
