extends QuantityInterface
class_name Area

## Area energy

func _init(_geom : Geometry) -> void:
	super(_geom)
	GRAD_KEY = "grad_area_key"
	description = "Area of figure"

func calc_grad_vertex(_v : Vertex, _neg : bool = false) -> void:
	super(_v)
	if globals.AMBIENT_DIMENSION != 3: return
	for f_id in _v.con_facets:
		var vector = geom.facets[ f_id ].get_oposite_side_rotated(_v)
		
		if not _neg: vector = -vector
		
		var grad = VectorN.new()
		grad.init(globals.AMBIENT_DIMENSION)
		grad.set_i(0, .5*vector.x)
		grad.set_i(1, .5*vector.y)
		grad.set_i(2, .5*vector.z)
		
		_v.add_force(GRAD_KEY, grad )

func calc_energy() -> float:
	var ret = 0.
	for f in geom.facets:
		ret += f.area()
	return ret
