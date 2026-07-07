extends RefCounted
class_name VectorN

var dimension : int = 0

var content : PackedFloat32Array

func init( _dim : int ) -> void:
	dimension = _dim
	content.resize(dimension)
	content.fill(0.)

func get_i( _i : int) -> float:
	return content[_i]

func set_i( _i : int, _content : float) -> void:
	content[_i] = _content

func fill( with : float ) -> void:
	for i in dimension:
		content[i] = with

func oposite() -> VectorN:
	var ret : VectorN = VectorN.new()
	ret.init(dimension)
	
	for i in dimension:
		ret.set_i(i, -content[i])
	
	return ret

func sum( with : VectorN ) -> VectorN:
	var ret : VectorN = VectorN.new()
	ret.init(dimension)
	
	if dimension != with.dimension:
		push_error("Attempting to sum two VectorN of different dimensions %s and %s" % [dimension, with.dimension])
		return ret
	
	for i in dimension:
		ret.set_i(i, content[i] + with.get_i(i))
	
	return ret

func product_by_scalar( factor : float ) -> VectorN:
	var ret : VectorN = VectorN.new()
	ret.init(dimension)
	
	for i in dimension:
		ret.set_i(i, factor * get_i(i))
	
	return ret

func subtract(with : VectorN) -> VectorN:
	var ret : VectorN = VectorN.new()
	ret.init(dimension)
	
	if dimension != with.dimension:
		push_error("Attempting to subtract two VectorN of different dimensions %s and %s" % [dimension, with.dimension])
		return ret
	
	for i in dimension:
		ret.set_i(i, content[i] - with.get_i(i))
	
	return ret

func dot( with : VectorN ) -> float:
	var ret : float = 0
	
	if dimension != with.dimension:
		push_error("Attempting to dot product two VectorN of different dimensions %s and %s" % [dimension, with.dimension])
		return ret
	
	for i in dimension:
		ret += content[i] * with.get_i(i)
	
	return ret

func mod() -> float:
	return sqrt(dot(self))
