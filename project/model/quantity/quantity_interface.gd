extends RefCounted
class_name QuantityInterface

## Quantity interface.
## Stores how to calculate both the quantity and the gradient (force) of the quantity.

var id : int = -1 : set = set_id
func set_id(_id) -> void:
	id = _id

var description : String = "Quantity interface"

## Key for the quantity
var GRAD_KEY : String = "gen_grad_key"

## Geometry over which the quantity and forces are calculated.
var geom : Geometry

## True if magnitude is constrained, false otherwise
var constrained : bool = false : set = set_constrained

func set_constrained(_c : bool) -> void:
	constrained = _c
	constraint_changed.emit(id, constrained)

signal constraint_changed

## Magnitude constraint, if it exists
var target : float = 0.0

## Facets included in the quantity
## Exact use of the array depends on the functions
## If it is empty it means the quantity is applied to all facets
var facets : Array = []

## Ids of facets included in the quantity
## Negative ids mean the facet should be considered in the opposite orientation
## -0.1 is the negative for 0
var facet_ids : PackedFloat32Array = []

signal removed

func _init(_geom) -> void:
	geom = _geom

func get_id() -> int:
	return id

func calc_gradients() -> void:
	for v in geom.vertices:
		calc_grad_vertex(v)

func calc_neg_gradients() -> void:
	for v in geom.vertices:
		calc_grad_vertex(v, true)

func set_magnitude_constraint(constraint : float) -> void:
	constrained = true
	target = constraint

func rm_magnitude_constraint() -> void:
	constrained = false

func calc_grad_vertex(_v : Vertex, _neg : bool = false) -> void:
	_v.set_force_zero( GRAD_KEY )

func calc_energy() -> float:
	return 0.

func remove() -> void:
	removed.emit(id)
	for f in facets:
		f.disconnect_quantity(self)

func has_facet( facet ) -> bool:
	return facets.has(facet)

func add_facet(_facet, op : bool = false) -> void:
	if id == -1:
		push_error("Quantity has not been assigned to the geometry and has no valid id")
		return
	facets.append(_facet)
	var fid = _facet.get_id()
	if op:
		fid = -fid
		if fid == 0: fid = -0.1
	facet_ids.append(fid)
	
	_facet.connect_quantity(self, op)

## Adds newly created facets created in the refinement.
## Assumes new facets are already created, in the facets array,
## and in the ordering given by refine().
func refine(_old_n_vertices : int, _old_n_edges : int, _old_n_facets : int) -> void:
	var old_n_facets_this = facets.size()
	for i in old_n_facets_this:
		add_facet( geom.facets[_old_n_facets + 3*abs(facet_ids[i])], facet_ids[i] < 0 )
		add_facet( geom.facets[_old_n_facets + 3*abs(facet_ids[i])+1], facet_ids[i] < 0 )
		add_facet( geom.facets[_old_n_facets + 3*abs(facet_ids[i])+2], facet_ids[i] < 0 )
