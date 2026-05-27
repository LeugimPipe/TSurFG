extends Node

var edge0
var edge1
var edge2

var view

func init( _edge0 = null, _edge1 = null, _edge2 = null) -> void:
	if view != null: view.queue_free()
	edge0 = _edge0
	edge1 = _edge1
	edge2 = _edge2
	
	# check edges form a closed loop
	if (edge0.head != edge1.tail):
		print("ERROR: head of edge 1 of facet is different from tail of edge 2")
		return
	
	if (edge1.head != edge2.tail):
		print("ERROR: head of edge 2 of facet is different from tail of edge 3")
		return
	
	if (edge2.head != edge0.tail):
		print("ERROR: head of edge 3 of facet is different from tail of edge 1")
		return
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/facet2d/view_facet_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/facet3d/view_facet_3d.tscn").instantiate()

	view.init(edge0, edge1, edge2)
	add_child(view)

# TODO: hacer mejor con el tipo futuro VectorN
func area() -> float:
	var v0 = Vector3(edge0.tail.coords[0], edge0.tail.coords[1], edge0.tail.coords[2])
	var v1 = Vector3(edge1.tail.coords[0], edge1.tail.coords[1], edge1.tail.coords[2])
	var v2 = Vector3(edge2.tail.coords[0], edge2.tail.coords[1], edge2.tail.coords[2])
	
	return (v1-v0).cross(v2-v1).length()/2

func is_vertex_in_facet(vertex) -> bool:
	if edge0.tail == vertex: return true
	if edge0.head == vertex: return true
	if edge1.tail == vertex: return true
	if edge1.head == vertex: return true
	if edge2.tail == vertex: return true
	if edge2.head == vertex: return true
	return false

func get_oposite_side(vertex):
	if !is_vertex_in_facet(vertex): return
	
	if edge0.tail == vertex: return edge1
	if edge0.head == vertex: return edge2
	if edge1.tail == vertex: return edge2
	if edge1.head == vertex: return edge0
	if edge2.tail == vertex: return edge0
	if edge2.head == vertex: return edge1

func get_oposite_side_rotated(vertex) -> Vector3:
	if !is_vertex_in_facet(vertex): return Vector3.ZERO
	
	var opside = get_oposite_side(vertex)
	var vecside = Vector3( opside.head.coords[0] - opside.tail.coords[0], opside.head.coords[1] - opside.tail.coords[1], opside.head.coords[2] - opside.tail.coords[2])
	
	var vece0 = Vector3( edge0.head.coords[0] - edge0.tail.coords[0], edge0.head.coords[1] - edge0.tail.coords[1], edge0.head.coords[2] - edge0.tail.coords[2])
	var vece1 = Vector3( edge1.head.coords[0] - edge1.tail.coords[0], edge1.head.coords[1] - edge1.tail.coords[1], edge1.head.coords[2] - edge1.tail.coords[2])
	var normal = vece0.cross(vece1).normalized()
	
	return vecside.rotated( normal, -PI/2)

func v0():
	return edge0.tail

func v1():
	return edge1.tail

func v2():
	return edge2.tail

func center() -> Array:
	var ret = [0, 0, 0]
	
	for i in 3:
		ret[i] = 1/3. * (v0().coords[i] + v1().coords[i] + v2().coords[i])
	
	return ret
