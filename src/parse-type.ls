# helpers
identifier-regex = /[\$\w]+/

function peek tokens # use instead of 'tokens.0' when it is required that the next token exists
  token = tokens.0
  throw new Error 'Unexpected end of input.' unless token?
  token

function consume-ident tokens
  token = peek tokens
  throw new Error "Expected text, got '#token' instead." unless identifier-regex.test token
  tokens.shift!

function consume-op tokens, op
  token = peek tokens
  throw new Error "Expected '#op', got '#token' instead." unless token is op
  tokens.shift!

function maybe-consume-op tokens, op
  token = tokens.0
  if token is op then tokens.shift! else null

# structures
function consume-array tokens
  consume-op tokens, '['
  throw new Error "Must specify type of Array - eg. [Type], got [] instead." if (peek tokens) is ']'
  types = consume-types tokens
  consume-op tokens, ']'
  {structure: 'array', of: types}

function consume-tuple tokens
  components = []
  consume-op tokens, '('
  throw new Error "Tuple must be of at least length 1 - eg. (Type), got () instead." if (peek tokens) is ')'
  for ever
    components.push consume-types tokens
    maybe-consume-op tokens, ','
    break if ')' is peek tokens
  consume-op tokens, ')'
  {structure: 'tuple', of: components}

function consume-fields tokens
  fields = {}
  consume-op tokens, '{'
  subset = false
  for ever
    if maybe-consume-op tokens, '...'
      subset := true
      break
    [key, types] = consume-field tokens
    fields[key] = types
    maybe-consume-op tokens, ','
    break if '}' is peek tokens
  consume-op tokens, '}'
  {structure: 'fields', of: fields, subset}

function consume-field tokens
  key = consume-ident tokens
  consume-op tokens, ':'
  types = consume-types tokens
  [key, types]

# core
function maybe-consume-structure tokens
  switch tokens.0
  | '[' => consume-array tokens
  | '(' => consume-tuple tokens
  | '{' => consume-fields tokens

function consume-type tokens
  token = peek tokens
  wildcard = token is '*'
  if wildcard or identifier-regex.test token
    type = if wildcard then consume-op tokens, '*' else consume-ident tokens
    structure = maybe-consume-structure tokens
    if structure then structure <<< {type} else {type}
  else
    structure = maybe-consume-structure tokens
    throw new Error "Unexpected character: #token" unless structure
    structure

function consume-types tokens
  if '::' is peek tokens
    throw new Error "No comment before comment separator '::' found."
  lookahead = tokens.1
  if lookahead? and lookahead is '::'
    tokens.shift! # remove comment
    tokens.shift! # remove ::
  types = []
  types-so-far = {} # for unique check
  if 'Maybe' is peek tokens
    tokens.shift!
    types =
      * type: 'Undefined'
      * type: 'Null'
    types-so-far = {+Undefined, +Null}
  for ever
    {type}:type-obj = consume-type tokens
    types.push type-obj unless types-so-far[type]
    types-so-far[type] = true
    break unless maybe-consume-op tokens, '|'
  types

# single char ops used : , [ ] ( ) } { | *
token-regex = //
    \.\.\.                       # etc op
  | ::                           # comment separator
  | ->                           # arrow (for error generation purposes)
  | #{ identifier-regex.source } # identifier
  | \S                           # all single char ops - valid, and non-valid (for error purposes)
  //g

module.exports = (input) ->
  throw new Error 'No type specified.' unless input.length
  tokens = (input.match token-regex or [])
  if '->' in tokens
    throw new Error "Function types are not supported.
                   \ To validate that something is a function, you may use 'Function'."
  try
    consume-types tokens
  catch
    throw new Error "#{e.message} - Remaining tokens: #{ JSON.stringify tokens } - Initial input: '#input'"
