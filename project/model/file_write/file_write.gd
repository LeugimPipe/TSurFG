extends RefCounted
class_name FileWriteInterface

## File writing strategy interface.

## File access
var file : FileAccess

## Geometry data
var geom : Geometry

func open_file(file_name : String) -> bool :
	file = FileAccess.open(file_name, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		push_error("Couldn't open file ", file_name)
		return false
	else:
		return true

## Writes to given file.
func write_to_file(_file_name : String, _geom : Geometry) -> bool:
	if not open_file(_file_name): return false
	geom = _geom
	return true
