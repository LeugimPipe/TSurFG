extends RefCounted
class_name VectorN

var dimension : int

var content : PackedFloat32Array

func init( _dim : int ) -> void:
	dimension = _dim
	content.resize(dimension)
	content.fill(0.)

func get_i( _i : int) -> float:
	return content[_i]

func set_i( _i : int, _content : float) -> void:
	content[_i] = _content
