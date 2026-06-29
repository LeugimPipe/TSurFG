extends Node
# TODO: probablemente no deberia ser un Node
# Sino algo mas ligero

var id : int = -1
var oid : int = -1

# TODO
# Las coordenadas deberian ser un tipo especial de Array a semejanza de Vector2 y Vector3
# Una cosa como VectorN
var coords : Array = []: set = set_coords
var saved_coords : Array = []
var fixed : bool = false

signal coords_changed

func set_coords(value : Array):
	coords = value.duplicate()
	if !globals.CALCULATING_STEP:
		coords_changed.emit(coords)

# Stores the indices of the connected vertices
# Same order as con_edges
var con_vertices : PackedInt32Array = []

# Stores which edges are connected to this vertex
# Stores the signed index
# Sign is positive if it's the tail, negative otherwise
var con_edges : PackedFloat32Array = []

# Stores which facets are connected to this vertex
var con_facets : PackedInt32Array = []

var view

@export var force_scene : PackedScene

# List of forces acting on the node
# Dictionary of Force nodes
var forces : Dictionary[String, Variant]

func save_coords() -> void:
	saved_coords = coords.duplicate()

func restore_coords() -> void:
	coords = saved_coords.duplicate()

# Initialize the vertex
func init(_id : int, _coords : Array = [], _oid : int = -1, _fixed : bool = false) -> void:
	id = _id
	coords = _coords
	if _oid != -1: oid = _oid
	fixed = _fixed
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/vertex2d/view_vertex_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/vertex3d/view_vertex_3d.tscn").instantiate()
	
	view.init(self)
	add_child(view)

func get_id() -> int:
	return id

func connect_edge(edge, tail: bool = true) -> void:
	var e_id = edge.get_id()
	
	var v_id = -1
	if tail:
		v_id = edge.head.get_id()
	else:
		v_id = edge.tail.get_id()
		e_id = -e_id
		if e_id == 0: e_id = -0.1
	
	if v_id in con_vertices:
		push_warning("WARNING: vertices %s and %s are already joined by an edge" % [get_id(), v_id])
	con_vertices.append(v_id)
	con_edges.append(e_id)

func connect_facet(facet) -> void:
	var f_id = facet.get_id()
	con_facets.append(f_id)

func is_vertex_connected(vertex) -> bool:
	return is_vertex_connected_id(vertex.get_id())

func is_vertex_connected_id(v_id : int) -> bool:
	return v_id in con_vertices

func is_edge_connected(edge) -> bool:
	return is_edge_connected_id(edge.get_id())

func is_edge_connected_id(e_id : int) -> bool:
	for index in con_edges:
		if e_id == abs(index):
			return true
	return false

## Empties arrays recording connections
func disconnect_everything() -> void:
	con_vertices.clear()
	con_edges.clear()
	con_facets.clear()

func get_edge_index_from_vertex(vector) -> float:
	return get_edge_index_from_v_id(vector.get_id())

func get_edge_index_from_v_id(v_id: int) -> float:
	var index = INF
	
	for ii in con_vertices.size():
		if con_vertices[ii] == v_id:
			index = con_edges[ii]
	
	return index

func get_as_vector():
	if globals.AMBIENT_DIMENSION == 2:
		return Vector2(coords[0], coords[1])
	if globals.AMBIENT_DIMENSION == 3:
		if coords.size() == 2:
			return Vector3(coords[0], coords[1], 0)
		if coords.size() == 3:
			return Vector3(coords[0], coords[1], coords[2])

## Creates zero force with given key
func init_force(key : String) -> void:
	var f : PackedFloat32Array
	f.resize(coords.size())
	f.fill(0.)
	forces[key] = force_scene.instantiate()
	forces[key].init(f)
	add_child(forces[key])

## Sets given force to zero if it exists.
## If it doesn't, it inits it at zero
func set_force_zero(key: String) -> void:
	if not forces.has(key):
		init_force(key)
	else:
		var f : PackedFloat32Array
		f.resize(coords.size())
		f.fill(0.)
		forces[key].init(f)

## Sets all existing forces to zero
func set_forces_zero() -> void:
	for key in forces:
		var f = forces[key]
		var f_coords : PackedFloat32Array
		f_coords.resize( coords.size() )
		f_coords.fill(0.)
		f.init(f_coords)

## Add force (supposed to be VectorN)
## to force indicated by key.
## If such force does not exist,
## inits it and adds it
func add_force(key : String, force : PackedFloat32Array) -> void:
	if not forces.has(key):
		init_force(key)
	
	forces[key].coords = [
		forces[key].coords[0] + force[0],
		forces[key].coords[1] + force[1],
		forces[key].coords[2] + force[2],
	]

func apply_forces(key : String) -> void:
	if not forces.has(key): return
	coords = [
		coords[0] + globals.time_step * forces[key].coords[0],
		coords[1] + globals.time_step * forces[key].coords[1],
		coords[2] + globals.time_step * forces[key].coords[2] ]

func apply_vector( key : String) -> void:
	if not forces.has(key): return
	coords = [
		coords[0] + forces[key].coords[0],
		coords[1] + forces[key].coords[1],
		coords[2] + forces[key].coords[2] ]
