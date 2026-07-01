extends Node
## Stores body information

var id : int = -1
var oid : int = -1

## Facets conforming the body
var facets : Array = []

## Ids of facets conforming the body
## Negative ids mean the facet should be considered in the opposite orientation
## -0.1 is the negative for 0
var facet_ids : PackedFloat32Array = []

var volume : float = -1.0

var volume_constraint : float = -1.0

var GRAD_VOLUME_BODY_KEY : String

func init(_id = -1, _oid = -1) -> void:
	if _id != -1: id = _id
	if _oid != -1: oid = _oid
	GRAD_VOLUME_BODY_KEY = "grad_volume_body_" + str(id) + "_key"

func get_id() -> int:
	return id

func set_volume(v : float) -> void:
	volume = v

func get_volume() -> float:
	return volume

func add_facet(_facet, op : bool = false) -> void:
	facets.append(_facet)
	var fid = _facet.get_id()
	if op:
		fid = -fid
		if fid == 0: fid = -0.1
	facet_ids.append(fid)
	
	_facet.connect_body(self, op)

func add_vol_constraint(_vol : float) -> void:
	volume_constraint = _vol

func has_facet( facet ) -> bool:
	return facets.has(facet)
