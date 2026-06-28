extends Node
## Stores body information

var id : int = -1
var oid : int = -1

## Facets conforming the body
var facets : Array = []

## Ids of facets conforming the body
var facet_ids : PackedInt32Array = []

var volume : float = -1.0

var volume_constraint : float = -1.0

var GRAD_VOLUME_BODY : String

func init(_id = -1, _oid = -1) -> void:
	if _id != -1: id = _id
	if _oid != -1: oid = _oid
	GRAD_VOLUME_BODY = "grad_volume_body_" + str(id) + "_key"

func get_id() -> int:
	return id

func set_volume(v : float) -> void:
	volume = v

func get_volume() -> float:
	return volume

func add_facet(_facet) -> void:
	facets.append(_facet)
	facet_ids.append(_facet.get_id())

func add_vol_constraint(_vol : float) -> void:
	volume_constraint = _vol

func has_facet( facet ) -> bool:
	return facet_ids.has(facet.get_id())
