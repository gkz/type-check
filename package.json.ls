name: 'type-check'
version: '0.3.1'

author: 'George Zahariev <z@georgezahariev.com>'
description: 'type-check allows you to check the types of JavaScript values at runtime with a Haskell like type syntax.'
homepage: 'https://github.com/gkz/type-check'
keywords:
  'type'
  'check'
  'checking'
  'library'
files:
  'lib'
  'README.md'
  'LICENSE'
main: './lib/'

bugs: 'https://github.com/gkz/type-check/issues'
license: 'MIT'
engines:
  node: '>= 0.8.0'
repository:
  type: 'git'
  url: 'git://github.com/gkz/type-check.git'
scripts:
  test: "make test"

dependencies:
  'prelude-ls': '~1.1.2'

dev-dependencies:
  livescript: '~1.4.0'
  mocha: '~2.3.4'
  istanbul: '~0.4.1'
  browserify: '~12.0.1'
