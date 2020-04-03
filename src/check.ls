{any, all, is-it-NaN} = require 'prelude-ls'

types =
  Number:
    type-of: 'Number'
    validate: -> not is-it-NaN it
  NaN:
    type-of: 'Number'
    validate: is-it-NaN
  Int:
    type-of: 'Number'
    validate: -> not is-it-NaN it and it % 1 is 0 # 1.0 is an Int
  Float:
    type-of: 'Number'
    validate: -> not is-it-NaN it # same as number
  Date:
    type-of: 'Date'
    validate: -> not is-it-NaN it.get-time! # make sure it isn't an invalid date

default-type =
  array: 'Array'
  tuple: 'Array'

function check-array input, type, options
  all (-> check-multiple it, type.of, options), input

function check-tuple input, type, options
  i = 0
  for types in type.of
    return false unless check-multiple input[i], types, options
    i++
  input.length <= i # may be less if using 'Undefined' or 'Maybe' at the end

function check-fields input, type, options
  input-keys = {}
  num-input-keys = 0
  for k of input
    input-keys[k] = true
    num-input-keys++
  num-of-keys = 0
  for key, types of type.of
    return false unless check-multiple input[key], types, options
    num-of-keys++ if input-keys[key]
  type.subset or num-input-keys is num-of-keys

function check-structure input, type, options
  return false if input not instanceof Object
  switch type.structure
  | 'fields' => check-fields input, type, options
  | 'array'  => check-array input, type, options
  | 'tuple'  => check-tuple input, type, options

function check input, type-obj, options
  {type, structure} = type-obj
  if type
    return true if type is '*' # wildcard
    setting = options.custom-types[type] or types[type]
    if setting
      (setting.type-of is void or setting.type-of is typeof! input)
        and setting.validate input
    else
      # Booleam, String, Null, Undefined, Error, user defined objects, etc.
      type is typeof! input and (not structure or check-structure input, type-obj, options)
  else if structure
    return false unless that is typeof! input if default-type[structure]
    check-structure input, type-obj, options
  else
    throw new Error "No type defined. Input: #input."

function check-multiple input, types, options
  throw new Error "Types must be in an array. Input: #input." unless typeof! types is 'Array'
  any (-> check input, it, options), types

module.exports = (parsed-type, input, options = {}) ->
  options.custom-types = {} unless options.custom-types?
  check-multiple input, parsed-type, options
