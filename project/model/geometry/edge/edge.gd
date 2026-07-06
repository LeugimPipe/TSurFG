extends Node
class_name Edge

var id : int = -1
var oid : int = -1

var tail
var head

var tail_id
var head_id

## Stores which facets are connected to this edge
var con_facets : PackedInt32Array = []

var view

func init(_id : int = -1, _tail = null, _head = null, _oid : int = -1 ) -> void:
	if view != null: view.queue_free()
	id = _id
	if _oid != -1: oid = _oid
	tail = _tail
	head = _head
	
	tail_id = tail.get_id()
	head_id = head.get_id()
	
	tail.connect_edge(self)
	head.connect_edge(self, false)
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/edge2d/view_edge_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/edge3d/view_edge_3d.tscn").instantiate()

	view.init(tail, head)
	add_child(view)

func connect_facet(facet) -> void:
	var f_id = facet.get_id()
	con_facets.append(f_id)

## Empties arrays recording connections
func disconnect_everything() -> void:
	con_facets.clear()

func get_id() -> int:
	return id

func midpoint() -> Array:
	var ret = [0, 0, 0]
	
	for i in 3:
		ret[i] = 0.5 * (tail.coords[i] + head.coords[i])
	
	return ret

func length() -> float:
	return (head.get_as_vector() - tail.get_as_vector()).length()

func vector() -> PackedFloat32Array:
	var ret : PackedFloat32Array
	ret.resize(globals.AMBIENT_DIMENSION)
	ret.fill(0.)
	
	for i in globals.AMBIENT_DIMENSION:
		ret[i] = head.coords[i] - tail.coords[i]
	
	return ret

func unit_vector() -> PackedFloat32Array:
	var l : float = length()
	var ret : PackedFloat32Array = vector()
	
	for i in globals.AMBIENT_DIMENSION:
		ret[i] /= l
	
	return ret
