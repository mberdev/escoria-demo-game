extends Reference
class_name ESCScanner


var _tokens: Array = []

var _current_line_tokens: Array = []

var _keywords: Dictionary
var _start: int = 0
var _current: int = 0
var _line: int = 1

var _source: String setget set_source

var _alpha_regex: RegEx
var _digit_regex: RegEx
var _alphanumeric_regex: RegEx

var _indent_level_stack: Array


func _init():
	_keywords["and"] = ESCTokenType.TokenType.AND
	_keywords["else"] = ESCTokenType.TokenType.ELSE
	_keywords["false"] = ESCTokenType.TokenType.FALSE
	_keywords["if"] = ESCTokenType.TokenType.IF
	_keywords["nil"] = ESCTokenType.TokenType.NIL
	_keywords["or"] = ESCTokenType.TokenType.OR
	_keywords["print"] = ESCTokenType.TokenType.PRINT
	_keywords["true"] = ESCTokenType.TokenType.TRUE
	_keywords["var"] = ESCTokenType.TokenType.VAR
	_keywords["while"] = ESCTokenType.TokenType.WHILE

	_alpha_regex = RegEx.new()
	_alpha_regex.compile("[a-zA-Z_]")

	_digit_regex = RegEx.new()
	_digit_regex.compile("[0-9]")

	_alphanumeric_regex = RegEx.new()
	_alphanumeric_regex.compile("[a-zA-Z0-9_]")
	
	_indent_level_stack.push_front(0)


func set_source(source: String) -> void:
	_source = source


func scan_tokens() -> Array:
	while not _at_end():
		_start = _current
		_scan_token()

	# Generate a DEDENT token for each indent level > 0 left on the stack
	while _indent_level_stack.pop_front() > 0:
		_add_token(ESCTokenType.TokenType.DEDENT, null)

	var token: ESCToken = ESCToken.new()
	token.init(ESCTokenType.TokenType.EOF, "", null, _line)
	_tokens.append(token)

	return _tokens
	

func _scan_token():
	var c: String = _advance()

	match c:
		'(':
			_add_token(ESCTokenType.TokenType.LEFT_PAREN, null)
		')':
			_add_token(ESCTokenType.TokenType.RIGHT_PAREN, null)
		'[':
			_add_token(ESCTokenType.TokenType.LEFT_SQUARE, null)
		']':
			_add_token(ESCTokenType.TokenType.RIGHT_SQUARE, null)
		',':
			_add_token(ESCTokenType.TokenType.COMMA, null)
		'.':
			_add_token(ESCTokenType.TokenType.DOT, null)
		'-':
			_add_token(ESCTokenType.TokenType.MINUS, null)
		'+':
			_add_token(ESCTokenType.TokenType.PLUS, null)
		'*':
			_add_token(ESCTokenType.TokenType.STAR, null)
		':':
			_add_token(ESCTokenType.TokenType.COLON, null)
		'/':
			_add_token(ESCTokenType.TokenType.SLASH, null)
		'|':
			_add_token(ESCTokenType.TokenType.PIPE, null)
		'?':
			_add_token(ESCTokenType.TokenType.QUESTION, null)
		'#':
			# the rest of the line is a comment
			while _peek() != '\n' and not _at_end():
				_advance()

		'\r', '\n':
			if not _all_whitespace(_current_line_tokens):
				_add_token(ESCTokenType.TokenType.NEWLINE, null)
				_check_indent()

			_line += 1
			_current_line_tokens = []
		'!':
			_add_token(ESCTokenType.TokenType.BANG_EQUAL if _match('=') else ESCTokenType.TokenType.BANG, null)
		'=':
			_add_token(ESCTokenType.TokenType.EQUAL_EQUAL if _match('=') else ESCTokenType.TokenType.EQUAL, null)
		'<':
			_add_token(ESCTokenType.TokenType.LESS_EQUAL if _match('=') else ESCTokenType.TokenType.LESS, null)
		'>':
			_add_token(ESCTokenType.TokenType.GREATER_EQUAL if _match('=') else ESCTokenType.TokenType.GREATER, null)

		' ', '\t':
			pass

		'"':
			_string()

		_:
			if _is_digit(c):
				_number()
			elif _is_alpha(c):
				_identifier()
			else:
				_error(_line, "Unexpected character.")


func _check_indent() -> void:
	var indent_level: int = 0

	while _match('\t'):
		indent_level += 1

	if indent_level > _indent_level_stack.front():
		_indent_level_stack.push_front(indent_level)
		_add_token(ESCTokenType.TokenType.INDENT, null)
	elif indent_level < _indent_level_stack.front():
		while _indent_level_stack.front() > indent_level:
			_indent_level_stack.pop_front()
			_add_token(ESCTokenType.TokenType.DEDENT, null)

		if _indent_level_stack.front() != indent_level:
			_error(_line, "Inconsistent indent.")


func _is_digit(c: String) -> bool:
	return _digit_regex.search(c) != null


func _is_alpha(c: String) -> bool:
	return _alpha_regex.search(c) != null


func _is_alphanumeric(c: String) -> bool:
	return _alphanumeric_regex.search(c) != null


func _identifier() -> void:
	while _is_alphanumeric(_peek()):
		_advance()

	var text: String = _source.substr(_start, _current - _start)
	var type = _keywords.get(text)

	if not type:
		type = ESCTokenType.TokenType.IDENTIFIER

	_add_token(type, null)


func _string() -> void:
	while _peek() != '"' and not _at_end():
		if _peek() == '\n':
			_line += 1
		_advance()

	if _at_end():
		_error(_line, "Unterimnated string.")
		return

	# Closing "
	_advance()

	# Trim surrounding quotes
	var value: String = _source.substr(_start + 1, (_current - 1) - (_start + 1))

	_add_token(ESCTokenType.TokenType.STRING, value)


func _number() -> void:
	while _is_digit(_peek()):
		_advance()

	# Fraction part?
	if _peek() == '.' and _is_digit(_peek_next()):
		_advance()

		while _is_digit(_peek()):
			_advance()

	_add_token(ESCTokenType.TokenType.NUMBER, _source.substr(_start, _current - _start).to_float())


# TODO: Move error reporting up when compiler is updated.
func _error(line: int, message: String) -> void:
	escoria.logger.error(
		self,
		"[Line %s]: %s" % [line, message]
	)

func _match(var expected: String) -> bool:
	if _at_end():
		return false;

	if _source[_current] != expected:
		return false

	_current += 1

	return true


func _peek() -> String:
	if _at_end():
		return "\\0"

	return _source[_current]


func _peek_next() -> String:
	if _current + 1 >= _source.length():
		return '\\0'

	return _source[_current + 1]


func _at_end() -> bool:
	return _current >= _source.length()


func _advance() -> String:
	var c: String = _source[_current]
	_current += 1
	return c


func _add_token(type: int, literal) -> void:
	var text: String = _source.substr(_start, _current - _start)
	var token: ESCToken = ESCToken.new()
	token.init(type, text, literal, _line)
	_tokens.append(token)
	_current_line_tokens.append(token)


func _all_whitespace(tokens: Array) -> bool:
	if tokens.size() == 0:
		return true

	for t in tokens:
		if not t.get_type() in [ESCTokenType.TokenType.INDENT, ESCTokenType.TokenType.NEWLINE]:
			return false

	return true
