extends QuantityInterface
class_name Length

## Length energy class

func _init(_geom : Geometry) -> void:
	super(_geom)
	GRAD_KEY = "grad_length_key"
	description = "Length of figure"

func calc_grad_vertex(_v : Vertex, _neg : bool = false) -> void:
	super(_v)
	for e_id in _v.con_edges:
		var grad : VectorN = geom.edges[abs(e_id)].unit_vector()
		
		if e_id >= 0:
			grad = grad.oposite()
		
		if _neg:
			grad = grad.oposite()
		
		_v.add_force(GRAD_KEY, grad )

func calc_energy() -> float:
	var ret = 0.
	for e in geom.edges:
		ret += e.length()
	return ret
