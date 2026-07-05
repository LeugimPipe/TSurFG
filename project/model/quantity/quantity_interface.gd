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

signal removed

func _init(_geom) -> void:
	geom = _geom

func get_id() -> int:
	return id

func calc_forces() -> void:
	for v in geom.vertices:
		calc_grad_vertex(v)

func set_magnitude_constraint(constraint : float) -> void:
	constrained = true
	target = constraint

func rm_magnitude_constraint() -> void:
	constrained = false

func calc_grad_vertex(_v : Vertex) -> void:
	_v.set_force_zero( GRAD_KEY )

func calc_energy() -> float:
	return 0.

func remove() -> void:
	removed.emit(id)
