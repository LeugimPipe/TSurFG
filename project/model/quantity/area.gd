extends QuantityInterface
class_name Area

## Area energy

func _init(_geom : Geometry) -> void:
	super(_geom)
	GRAD_KEY = "grad_area_key"
	description = "Area of figure"

func calc_grad_vertex(_v : Vertex) -> void:
	super(_v)
	for f_id in _v.con_facets:
		var vector = geom.facets[ f_id ].get_oposite_side_rotated(_v)
		
		_v.add_force(GRAD_KEY, [.5*vector.x, .5*vector.y, .5*vector.z] )

func calc_energy() -> float:
	var ret = 0.
	for f in geom.facets:
		ret += f.area()
	return ret
