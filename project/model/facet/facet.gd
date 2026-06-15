extends Node

var edge0
var edge1
var edge2

var inversee0
var inversee1
var inversee2

var v0
var v1
var v2

var view

func init( _edge0, _edge1, _edge2, _inversee0 : bool = false, _inversee1 : bool = false, _inversee2 : bool = false) -> void:
	if view != null: view.queue_free()
	edge0 = _edge0
	edge1 = _edge1
	edge2 = _edge2
	
	inversee0 = _inversee0
	inversee1 = _inversee1
	inversee2 = _inversee2
	
	if inversee0: v0 = edge0.head
	else: v0 = edge0.tail
	
	if inversee1: v1 = edge1.head
	else: v1 = edge1.tail
	
	if inversee2: v2 = edge2.head
	else: v2 = edge2.tail
	
	# check edges form a closed loop
	if inversee0:
		if v1 != edge0.tail:
			print("ERROR: head of edge 0 of facet is different from tail of edge 1")
			return
	else:
		if v1 != edge0.head:
			print("ERROR: head of edge 0 of facet is different from tail of edge 1")
			return
	
	if inversee1:
		if v2 != edge1.tail:
			print("ERROR: head of edge 1 of facet is different from tail of edge 2")
			return
	else:
		if v2 != edge1.head:
			print("ERROR: head of edge 1 of facet is different from tail of edge 2")
			return
	
	if inversee2:
		if v0 != edge2.tail:
			print("ERROR: head of edge 2 of facet is different from tail of edge 0")
			return
	else:
		if v0 != edge2.head:
			print("ERROR: head of edge 2 of facet is different from tail of edge 0")
			return
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/facet2d/view_facet_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/facet3d/view_facet_3d.tscn").instantiate()

	view.init(v0, v1, v2)
	add_child(view)

# TODO: hacer mejor con el tipo futuro VectorN
func area() -> float:
	var v0 = get_v0().get_as_vector()
	var v1 = get_v1().get_as_vector()
	var v2 = get_v2().get_as_vector()
	
	return (v1-v0).cross(v2-v1).length()/2

func volume_contribution() -> float:
	var ret: float = 0.
	
	var v0 = get_v0().get_as_vector()
	var v1 = get_v1().get_as_vector()
	var v2 = get_v2().get_as_vector()
	
	ret = v0.dot(v1.cross(v2))
	
	return ret/6.

func is_vertex_in_facet(vertex) -> bool:
	if edge0.tail == vertex: return true
	if edge0.head == vertex: return true
	if edge1.tail == vertex: return true
	if edge1.head == vertex: return true
	if edge2.tail == vertex: return true
	if edge2.head == vertex: return true
	return false

func get_next_vertex(vertex):
	if !is_vertex_in_facet(vertex): return
	
	if vertex == v0: return v1
	if vertex == v1: return v2
	if vertex == v2: return v0

func get_prev_vertex(vertex):
	if !is_vertex_in_facet(vertex): return
	
	if vertex == v0: return v2
	if vertex == v1: return v0
	if vertex == v2: return v1

func get_oposite_side_rotated(vertex) -> Vector3:
	if !is_vertex_in_facet(vertex): return Vector3.ZERO
	
	var vecside = get_prev_vertex(vertex).get_as_vector() - get_next_vertex(vertex).get_as_vector()
	
	var vece0 = v1.get_as_vector() - v0.get_as_vector()
	var vece1 = v2.get_as_vector() - v1.get_as_vector()
	var normal = vece0.cross(vece1).normalized()
	
	return vecside.rotated( normal, -PI/2)

func get_v0():
	return v0

func get_v1():
	return v1

func get_v2():
	return v2

func center() -> Array:
	var ret = [0, 0, 0]
	
	for i in 3:
		ret[i] = 1/3. * (v0.coords[i] + v1.coords[i] + v2.coords[i])
	
	return ret
