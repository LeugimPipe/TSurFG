extends Node
class_name Facet

var id : int = -1
var oid : int = -1

var edge0 : Edge
var edge1 : Edge
var edge2 : Edge

var inversee0 : bool
var inversee1 : bool
var inversee2 : bool

var v0 : Vertex
var v1 : Vertex
var v2 : Vertex

var view

var edge0_id : int
var edge1_id : int
var edge2_id : int

var v0_id : int
var v1_id : int
var v2_id : int

## Stores the id of quantities to which it is connected.
## Negative ids mean the facet should be considered in the opposite orientation.
## -0.1 is the negative for 0.
var con_quants : PackedFloat32Array = []

func init(_id: int, _edge0 : Edge, _edge1 : Edge, _edge2 : Edge, _inversee0 : bool = false, _inversee1 : bool = false, _inversee2 : bool = false,  _oid : int = -1) -> void:
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
	
	if id == 0:
		print(v0_vector)
		print(v1_vector)
		print(v2_vector)
	
	return (v1_vector-v0_vector).cross(v2_vector-v1_vector).length()/2

func volume_contribution() -> float:
	var ret: float = 0.

	var v0_vector = get_v0().get_as_vector()
	var v1_vector = get_v1().get_as_vector()
	var v2_vector = get_v2().get_as_vector()
	
	ret = v0_vector.dot(v1_vector.cross(v2_vector))
	
	return ret/6.

func is_vertex_in_facet(vertex : Vertex) -> bool:
	if edge0.tail == vertex: return true
	if edge0.head == vertex: return true
	if edge1.tail == vertex: return true
	if edge1.head == vertex: return true
	if edge2.tail == vertex: return true
	if edge2.head == vertex: return true
	return false

func get_next_vertex(vertex : Vertex):
	if !is_vertex_in_facet(vertex): return
	
	if vertex == v0: return v1
	if vertex == v1: return v2
	if vertex == v2: return v0

func get_prev_vertex(vertex : Vertex):
	if !is_vertex_in_facet(vertex): return
	
	if vertex == v0: return v2
	if vertex == v1: return v0
	if vertex == v2: return v1

func get_oposite_side_rotated(vertex : Vertex) -> Vector3:
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

func center() -> VectorN:
	var ret : VectorN = VectorN.new()
	ret.init(globals.AMBIENT_DIMENSION)
	
	ret = v0.coords.sum( v1.coords )
	ret = ret.sum( v2.coords )
	ret = ret.product_by_scalar( 1/3. )
	
	return ret

func get_id() -> int:
	return id

func connect_quantity(quantity : QuantityInterface, inverse : bool = false) -> void:
	var q_id = quantity.get_id()
	if inverse:
		q_id = -q_id
		if q_id == 0: q_id = -0.1
	if con_quants.has(q_id):
		push_error("Facet ", id, " is already connected to quantity ", q_id)
		return
	
	con_quants.append(q_id)

func is_quantity_connected_id(q_id : int) -> bool:
	if con_quants.has(q_id) : return true
	if con_quants.has(-q_id) : return true
	if q_id == 0:
		if con_quants.has(0) : return true
		if con_quants.has(-0.1): return true
	return false

func is_quantity_connected(quantity : QuantityInterface) -> bool:
	return is_quantity_connected_id(quantity.get_id())

func is_quantity_inverse_id(q_id : int) -> bool:
	if q_id == 0: return con_quants.has(-0.1)
	return con_quants.has(-q_id)

func is_quantity_inverse(quantity : QuantityInterface) -> bool:
	return is_quantity_inverse_id(quantity.get_id())

func disconnect_quantity(quantity : QuantityInterface) -> void:
	var q_id = quantity.id
	con_quants.erase(q_id)
	con_quants.erase(-q_id)
	if q_id == 0: con_quants.erase(-0.1)
