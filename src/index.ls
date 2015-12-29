VERSION = '0.3.2'
parse-type = require './parse-type'
parsed-type-check = require './check'

type-check = (type, input, options) ->
  parsed-type-check (parse-type type), input, options

module.exports = {VERSION, type-check, parsed-type-check, parse-type}
