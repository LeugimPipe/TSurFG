extends Node

var id : int = -1
var oid : int = -1

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

var edge0_id
var edge1_id
var edge2_id

var v0_id
var v1_id
var v2_id

## Stores the id of the body to which it is connected.
## The facet is part of the body with its correct orientation.
var body_id : int = -1

## Stores the id of the body to which it is connected.
## The facet is part of the body with its inverse orientation.
var bodyinverse_id : int = -1

func init(_id: int, _edge0, _edge1, _edge2, _inversee0 : bool = false, _inversee1 : bool = false, _inversee2 : bool = false,  _oid : int = -1) -> void:
	if view != null: view.queue_free()
	
	id = _id
	if _oid != -1: oid = _oid
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
			push_error("In facet %s head of edge 0 is different from tail of edge 1" % id)
			return
	else:
		if v1 != edge0.head:
			push_error("In facet %s head of edge 0 is different from tail of edge 1" % id)
			return
	
	if inversee1:
		if v2 != edge1.tail:
			push_error("In facet %s head of edge 1 is different from tail of edge 2" % id)
			return
	else:
		if v2 != edge1.head:
			push_error("In facet %s head of edge 1 is different from tail of edge 2" % id)
			return
	
	if inversee2:
		if v0 != edge2.tail:
			push_error("In facet %s head of edge 2 is different from tail of edge 0" % id)
			return
	else:
		if v0 != edge2.head:
			push_error("In facet %s head of edge 2 is different from tail of edge 0" % id)
			return
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/facet2d/view_facet_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/facet3d/view_facet_3d.tscn").instantiate()

	view.init(v0, v1, v2)
	add_child(view)
	
	edge0_id = edge0.get_id()
	edge1_id = edge1.get_id()
	edge2_id = edge2.get_id()
	
	v0_id = v0.get_id()
	v1_id = v1.get_id()
	v2_id = v2.get_id()
	
	edge0.connect_facet(self)
	edge1.connect_facet(self)
	edge2.connect_facet(self)
	
	v0.connect_facet(self)
	v1.connect_facet(self)
	v2.connect_facet(self)

# TODO: hacer mejor con el tipo futuro VectorN
func area() -> float:
	var v0_vector = get_v0().get_as_vector()
	var v1_vector = get_v1().get_as_vector()
	var v2_vector = get_v2().get_as_vector()
	
	return (v1_vector-v0_vector).cross(v2_vector-v1_vector).length()/2

func volume_contribution() -> float:
	var ret: float = 0.
	
	var v0_vector = get_v0().get_as_vector()
	var v1_vector = get_v1().get_as_vector()
	var v2_vector = get_v2().get_as_vector()
	
	ret = v0_vector.dot(v1_vector.cross(v2_vector))
	
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

func get_id() -> int:
	return id

func connect_body(body, inverse : bool = false) -> void:
	var b_id : int = body.get_id()
	if body_id == b_id or bodyinverse_id == b_id:
		push_error("Facet ", get_id(), " is already connected to body ", b_id)
		return
	
	if b_id == body_id:
		push_error("Facet ", get_id(), " is already connected to body ", b_id)
		return
	
	if b_id == bodyinverse_id:
		push_error("Facet ", get_id(), " is already connected to body ", b_id, " with inverse orientation")
		return

	if inverse:
		if bodyinverse_id != -1:
			push_error("Cannot connect facet ", get_id(), " to body ", b_id, " with inverse orientation: it is already connected to body ", bodyinverse_id, " with inverse orientation.")
			return
		
		bodyinverse_id = b_id
	
	else:
		if body_id != -1:
			push_error("Cannot connect facet ", get_id(), " to body ", b_id, ": it is already connected to body ", body_id, ".")
			return
		
		body_id = b_id

func is_body_connected_id(b_id : int) -> bool:
	if b_id == body_id: return true
	if b_id == bodyinverse_id: return true
	return false

func is_body_connected(body) -> bool:
	return is_body_connected_id(body.get_id())

func is_body_inverse_id(b_id : int) -> bool:
	return b_id == bodyinverse_id

func is_body_inverse(body) -> bool:
	return is_body_inverse_id(body.get_id())
