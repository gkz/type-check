{deep-equal, throws}:assert = require 'assert'
{parse-type: p} = require '..'

suite 'parse type' ->
  test 'simple' ->
    deep-equal (p 'Number'), [type: 'Number']

  test 'different characters' ->
    deep-equal (p '2T_and$'), [type: '2T_and$']

  test 'Maybe' ->
    deep-equal (p 'Maybe Number'), [
      * type: 'Undefined'
      * type: 'Null'
      * type: 'Number'
    ]
    deep-equal (p 'Maybe Null | Number'), [
      * type: 'Undefined'
      * type: 'Null'
      * type: 'Number'
    ]
    deep-equal (p 'Maybe Undefined | String'), [
      * type: 'Undefined'
      * type: 'Null'
      * type: 'String'
    ]

  test 'wildcard' ->
    deep-equal (p '*'), [type: '*']
    deep-equal (p '[*]'), [
      structure: 'array'
      of: [type: '*']
    ]
    deep-equal (p '{x: *}'), [
      structure: 'fields'
      of:
        x: [type: '*']
      subset: false
    ]
    deep-equal (p '*{a:Number}'), [
      type: '*'
      structure: 'fields'
      of:
        a: [type: 'Number']
      subset: false
    ]

  suite 'multiple types' ->
    test 'one' ->
      deep-equal (p 'Number'), [type: 'Number']

    test 'two' ->
      deep-equal (p 'Number | String'), [
        * type: 'Number'
        * type: 'String'
      ]

    test 'three' ->
      deep-equal (p 'Number | String | Float'), [
        * type: 'Number'
        * type: 'String'
        * type: 'Float'
      ]

    test 'two' ->
      deep-equal (p 'Number | Number'), [
        * type: 'Number'
      ]


  suite 'array structure' ->
    test 'simple' ->
      deep-equal (p '[Number]'), [
        structure: 'array'
        of: [type: 'Number']
      ]

    test 'nested' ->
      deep-equal (p '[[Number]]'), [
        structure: 'array'
        of: [
          structure: 'array'
          of: [type: 'Number']
        ]
      ]

  suite 'array structure with type' ->
    test 'simple' ->
      deep-equal (p 'Int16Array[Int]'), [
        type: 'Int16Array'
        structure: 'array'
        of: [type: 'Int']
      ]

    test 'nested' ->
      deep-equal (p 'Array[Float32Array[Float]]'), [
        type: 'Array'
        structure: 'array'
        of: [
          type: 'Float32Array'
          structure: 'array'
          of: [type: 'Float']
        ]
      ]

  suite 'tuple structure' ->
    test 'single' ->
      deep-equal (p '(Number)'), [
        structure: 'tuple'
        of: [
          [type: 'Number']
        ]
      ]

    test 'double' ->
      deep-equal (p '(Number, String)'), [
        structure: 'tuple'
        of: [
          [type: 'Number']
          [type: 'String']
        ]
      ]

    test 'trailing comma' ->
      deep-equal (p '(Number, String,)'), [
        structure: 'tuple'
        of: [
          [type: 'Number']
          [type: 'String']
        ]
      ]

    test 'nested' ->
      deep-equal (p '((Number, String), (Float))'), [
        structure: 'tuple'
        of:
          * [{
              structure: 'tuple'
              of:
                * [type: 'Number']
                * [type: 'String']
            }]
          * [{
              structure: 'tuple'
              of: [[type: 'Float']]
            }]
      ]

  suite 'tuple structure with type' ->
    test 'double' ->
      deep-equal (p 'Type(Number, String)'), [
        type: 'Type'
        structure: 'tuple'
        of: [
          [type: 'Number']
          [type: 'String']
        ]
      ]

    test 'nested' ->
      deep-equal (p 'Type(Type2(Number, String), Type3(Float))'), [
        type: 'Type'
        structure: 'tuple'
        of:
          * [{
              type: 'Type2'
              structure: 'tuple'
              of:
                * [type: 'Number']
                * [type: 'String']
            }]
          * [{
              type: 'Type3'
              structure: 'tuple'
              of: [[type: 'Float']]
            }]
      ]


  suite 'fields structure, without type' ->
    test 'simple' ->
      deep-equal (p '{a:Number, b:String}'), [
        structure: 'fields'
        of:
          a: [type: 'Number']
          b: [type: 'String']
        subset: false
      ]

    test 'trailing comma' ->
      deep-equal (p '{a:Number, b:String,}'), [
        structure: 'fields'
        of:
          a: [type: 'Number']
          b: [type: 'String']
        subset: false
      ]

    test 'nested' ->
      deep-equal (p '{a: {message: String}, b:String}'), [
        structure: 'fields'
        of:
          a: [{
            structure: 'fields'
            of:
              message: [type: 'String']
            subset: false
          }]
          b: [type: 'String']
        subset: false
      ]

    test 'subset' ->
      deep-equal (p '{a:Number, ...}'), [
        structure: 'fields'
        of:
          a: [type: 'Number']
        subset: true
      ]

    test 'no fields specified' ->
      deep-equal (p '{...}'), [
        structure: 'fields'
        of: {}
        subset: true
      ]

  suite 'fields structure, with type' ->
    test 'simple' ->
      deep-equal (p 'Object{a:Number, b:String}'), [
        type: 'Object'
        structure: 'fields'
        of:
          a: [type: 'Number']
          b: [type: 'String']
        subset: false
      ]

    test 'nested' ->
      deep-equal (p 'Object{a: Error{message: String}, b:String}'), [
        type: 'Object'
        structure: 'fields'
        of:
          a: [{
            type: 'Error'
            structure: 'fields'
            of:
              message: [type: 'String']
            subset: false
          }]
          b: [type: 'String']
        subset: false
      ]

    test 'subset' ->
      deep-equal (p 'Node{a:Number, ...}'), [
        type: 'Node'
        structure: 'fields'
        of:
          a: [type: 'Number']
        subset: true
      ]

    test 'no fields specified' ->
      deep-equal (p 'Date{...}'), [
        type: 'Date'
        structure: 'fields'
        of: {}
        subset: true
      ]

  suite 'errors' ->
    test 'no type specified' ->
      throws (-> p ''), /No type specified/

    test 'tuple of length 0' ->
      throws (-> p '()'), /Tuple must be of at least length 1/

    test 'array without type' ->
      throws (-> p '[]'), /Must specify type of Array/

    test 'unexpected end of input' ->
      throws (-> p ' '), /Unexpected end of input/
      throws (-> p '['), /Unexpected end of input/
      throws (-> p '[Number'), /Unexpected end of input/
      throws (-> p '{'), /Unexpected end of input/

    test 'unexpected end of input (input never tokenized)' ->
      throws (-> p '{Number:'), /Unexpected end of input/

    test 'unexpected character' ->
      throws (-> p '[)'), /Unexpected character: \)/
      throws (-> p '^'), /Unexpected character: \^/

    test 'function types not supported' ->
      throws (-> p 'Number -> String'), /Function types are not supported. To validate that something is a function, you may use 'Function'/

    test 'expected op' ->
      throws (-> p '[Number)'), /Expected '\]', got '\)' instead/

    test 'expected text' ->
      throws (-> p '{:Number}'), /Expected text, got ':' instead/
