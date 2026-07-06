extends RefCounted
class_name FileReadInterface

## File reading strategy interface.

var file_content : String
var geom : Geometry

# FILE PROCESSING UTILS

func is_white_space(s : String) -> bool:
	return s == " " or s == "\t"

func is_new_line(s : String) -> bool:
	return s == "\n"

func is_new_line_or_white(s : String) -> bool:
	return is_white_space(s) or is_new_line(s)

# Consumes first n characters
func consume(n: int) -> void:
	file_content = file_content.right( -n )

func check_head(check: String) -> bool:
	consume_white_or_end_line()
	return file_content.left(check.length()) == check

## Consume file_content until nth character
func consume_until(s : String, n : int = 1) -> void:
	for i in n:
		var pos = file_content.find(s)
		if pos != -1:
			consume( pos+s.length() )

func consume_line(n: int = 1) -> void:
	consume_until("\n", n)

## Returns and consumes first part of file_content
## (default separator first white character)
func get_and_consume_head(separator: String = "") -> String:
	var ret : String
	
	consume_white_or_end_line()
	
	if separator != "":
		var pos_sep = file_content.find(separator)
		ret = file_content.left( pos_sep )
		consume( pos_sep+1 )
	else:
		
		while file_content.length() > 0 and !is_new_line_or_white(file_content[0]):
			ret += file_content[0]
			consume(1)
	
	consume_white_or_end_line()
	
	return ret

func get_and_consume_head_respect_eol() -> String:
	var ret : String = ""
	consume_white_space()
	
	while file_content.length() > 0 and not is_new_line_or_white(file_content[0]):
		ret += file_content[0]
		consume(1)
	
	consume_white_space()
	return ret

func get_and_consume_rest_of_line() -> String:
	var ret : String = ""
	
	while file_content.length() > 0 and not is_new_line(file_content[0]):
		ret += file_content[0]
		consume(1)
	
	consume_white_or_end_line()
	return ret

func consume_white_space() -> void:
	while file_content.length() > 0 and is_white_space(file_content[0]):
		consume(1)

func consume_end_line() -> void:
	while file_content.length() > 0 and is_new_line(file_content[0]):
		consume(1)

func consume_white_or_end_line() -> void:
	while file_content.length() > 0 and is_new_line_or_white(file_content[0]):
		consume(1)

## Consumes next word
## (consumes white space,
## consumes whatever is next until it hits whitespace again,
## and then consumes white space again)
func consume_word(n: int = 1) -> void:
	for i in n:
		consume_white_or_end_line()
		while file_content.length() > 0 and !is_new_line_or_white(file_content[0]):
			consume(1)
		consume_white_or_end_line()

func check_head_is_int() -> bool:
	for i in 10:
		if check_head( str(i) ): return true
		if check_head( str(-i) ): return true
	if check_head( "-0" ): return true
	return false

## Checks first characters of file_content match check
## And if so consumes them
## Else displays error message
## Consumes white spaces and endlines before and after check
func check_and_consume_head(check: String) -> bool:
	consume_white_or_end_line()
	
	if check_head(check):
		consume( check.length() )
		consume_white_or_end_line()
		return true
	
	error()
	
	return false

func error() -> void:
	pass

func erase_comments() -> void:
	pass

func load_file(_file_content : String, _geom : Geometry) -> bool:
	file_content = _file_content
	geom = _geom
	return false
