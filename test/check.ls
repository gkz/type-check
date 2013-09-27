{throws}:assert = require 'assert'
{type-check: c, parsed-type-check} = require '..'

suite 'check' ->
  test 'Undefined' ->
    assert c 'Undefined', void
    assert c 'Undefined', Math.FAKE
    assert not c 'Undefined', null
    assert not c 'Undefined', false

  test 'Undefined in field' ->
    assert c '{a: Undefined}', {}
    assert c '{a: Undefined}', {a: void}
    assert not c '{a: Undefined}', {a: 1}

  test 'Undefined in tuple' ->
    assert c '(Undefined, Number)', [void, 2]
    assert not c '(Undefined, Number)', [1, 2]

  test 'Null' ->
    assert c 'Null', null
    assert not c 'Null', void
    assert not c 'Null', false

  test 'Boolean' ->
    assert c 'Boolean', true
    assert c 'Boolean', false
    assert c 'Boolean', new Boolean false
    assert not c 'Boolean', 1

  test 'String' ->
    assert c 'String', 'hi'
    assert c 'String', new String 'hi'
    assert not c 'String', 2

  test 'Number' ->
    assert c  'Number', 2
    assert c  'Number', new Number 2
    assert not c 'Number', 'hi'

  test 'NaN' ->
    assert c 'NaN', NaN
    assert not c 'NaN', 1

  test 'Int' ->
    assert c 'Int', 1
    assert c 'Int', 1.0
    assert not c 'Int', 1.1

  test 'Float' ->
    assert c 'Float', 1
    assert c 'Float', 1.0
    assert c 'Float', 1.1

  test 'Date' ->
    assert c 'Date', new Date '2011-11-11'
    assert not c 'Date', new Date '2011-1111'

  test 'Function' ->
    assert c 'Function', ->

  test 'wildcard' ->
    assert c '*', void
    assert c '*', null
    assert c '*', 2
    assert c '*', {}
    assert c '*', new Error
    assert c '[*]', [1, null, void, 'hi', {x: 22}]

  test 'multiple' ->
    assert c 'Number | String', 'hi'
    assert not c 'Date | Number', 'hi'

  suite 'Array' ->
    test 'bare' ->
      assert c 'Array', [1, 2, 3]
      assert c 'Array', [1, 'hi']
      assert not c 'Array', true

    test 'simple' ->
      assert c '[Number]', [1, 2, 3]

    test 'incorrect type' ->
      assert not c '[Number]', true

    test 'incorrect element type' ->
      assert not c '[Number]', [1, 'hi']

  suite 'Tuple' ->
    test 'simple' ->
      assert c '(String, Number)', ['hi', 2]

    test 'too long' ->
      assert not c '(String, Number)', ['hi', 2, 1]

    test 'too short' ->
      assert not c '(String, Number)', ['hi']

    test 'incorrect type' ->
      assert not c '(String, Number)', {}

    test 'incorrect element type' ->
      assert not c '(String, Number)', ['hi', 'bye']

  test 'bare Object' ->
    assert c 'Object', {}
    assert c 'Object', {a: 1, length: 1}
    assert not c 'Object', new Date

  suite 'Maybe' ->
    test 'simple' ->
      assert c 'Maybe Number', 1
      assert c 'Maybe Number', null
      assert not c 'Maybe Number', 'string'

    test 'with multiple' ->
      type = 'Maybe Number | String'
      assert c type, 2
      assert c type, null
      assert c type, 'hi'

    test 'in fields' ->
      type = '{a: Maybe String}'
      assert c type, {a: 'string'}
      assert c type, {a: null}
      assert c type, {}
      assert not c type, {a: 2}

    test 'in tuple' ->
      type = '(Number, Maybe String)'
      assert c type, [1, 'hi']
      assert c type, [1, null]
      assert c type, [1]
      assert not c '(Maybe String, Number)', [2]

    test 'in array' ->
      assert c '[Maybe Number]', [1, null, 2, void, 23]
      assert c 'Object[Maybe String]', {0: 'a', 2: null, 5: 'b', length: 6}

  suite 'duck typing' ->
    test 'basic' ->
      assert c '{a: String}', {a: 'hi'}

    test 'property must by appropriate type' ->
      assert not c '{a: String}', {a: 2}

    test 'key must be the same' ->
      assert not c '{a: String}', {b: 'hi'}

    test 'not an object - fails' ->
      assert not c '{a: String}', 2

    test 'non-enumerable properties' ->
      assert c '{parse: Function, stringify: Function}', JSON

    test 'enumerable and non-enumerable properties' ->
      assert c '{0: Number, 1: Number, length: Number}', [1, 2]

    test 'using spread operator to check only a subset of the properties' ->
      assert c '{length: Number, ...}', [1, 2]

  suite 'structures with types' ->
    test 'fields with Object' ->
      assert c 'Object{a: String}', {a: 'hi'}
      assert not c 'Object{a: String}', {a: 2}

    test 'fields with Array' ->
      assert c 'Array{0:Number, 1:Number, 2:Number}', [1, 2, 3]
      assert c 'Array{0:Number, 1:Number, 2:Number}', [1, 2, 3]
      assert c 'Array{0:Number, 1:String}', [1, 'hi']
      assert not c 'Array{0:Number, 1:String}', [1]

    test 'fields with JSON' ->
      assert c 'JSON{parse: Function, stringify: Function}', JSON
      assert not c 'JSON{parse: Function, stringify: Function}', {parse: ->, stringify: ->}

    test 'fields with Math (using subset)' ->
      assert c 'Math{PI: Float, sqrt: Function, ...}', Math

    test 'array structure with Array' ->
      assert c 'Array[Number]', [1, 2]

    test 'array structure with Object' ->
      assert c 'Object[Number]', {0: 1, 1: 2, length: 2}

    test 'tuple structure with Array' ->
      assert c 'Array(Number, String)', [1, 'two']

    test 'tuple structure with Object' ->
      assert c 'Object(Number, String)', {0: 1, 1: 'two', length: 2}

  suite 'custom types' ->
    test 'simple' ->
      o =
        custom-types:
          Even:
            type-of: 'Number'
            validate: -> it % 2 is 0
      assert c 'Even', 2, o
      assert not c 'Even', 1, o

    test 'overwrite current' ->
      o =
        custom-types:
          Undefined:
            type-of: 'String'
            validate: -> it is 'bananas'

      assert c 'Undefined', 'bananas', o
      assert not c 'Undefined', void, o

  test 'nested' ->
    type = '{a: (String, [Number], {x: {a: Maybe Number}, y: Array, ...}), b: Error{message: String, ...}}'
    assert c type, {a: ['hi', [1, 2, 3], {x: {a: 42}, y: [1, 'bye']}], b: new Error 'message'}
    assert c type, {a: ['moo', [3], {x: {}, y: [], z: 999}], b: new Error '23'}

  suite 'errors' ->
    test 'no type defined' ->
      throws (-> parsed-type-check [{}], true), /No type defined\. Input: true/

    test 'types must be in array' ->
      throws (-> parsed-type-check {}, true), /Types must be in an array\. Input: true/
