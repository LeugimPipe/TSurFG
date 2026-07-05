extends QuantityInterface
class_name VolumeBody

## Volume computation strategy class.

func set_id(_id) -> void:
	super(_id)
	GRAD_KEY = "grad_volume_body_" + str(id) + "_key"

var oid : int = -1

## Facets conforming the body
var facets : Array = []

## Ids of facets conforming the body
## Negative ids mean the facet should be considered in the opposite orientation
## -0.1 is the negative for 0
var facet_ids : PackedFloat32Array = []

func _init(_geom : Geometry, _oid : int = -1) -> void:
	super(_geom)
	if _oid != -1: oid = _oid
	GRAD_KEY = "grad_volume_body_" + str(id) + "_key"
	description = "Body volume"

func calc_grad_vertex(_v : Vertex) -> void:
	super(_v)
	for fid in _v.con_facets:
		var f = geom.facets[fid]
		if f.is_body_connected(self):
			var q = f.get_next_vertex(_v).get_as_vector()
			var r = f.get_prev_vertex(_v).get_as_vector()
			var prod = q.cross(r)
			
			# If the id is negative the volume contribution should be the opposite
			# as the actual volume contribution is the one that would result from a
			# facet with the opposite orientation.
			if f.is_body_inverse(self): prod = -prod
			
			_v.add_force( GRAD_KEY, [ 1/6. * prod.x, 1/6. * prod.y, 1/6. * prod.z] )

func calc_energy() -> float:
	var vol = 0.
	
	for i in facets.size():
		var f = facets[i]
		var vol_contr : float = f.volume_contribution()
		# If the id is negative the volume contribution should be the opposite
		# as the actual volume contribution is the one that would result from a
		# facet with the opposite orientation.
		if facet_ids[i] < 0 : vol_contr = -vol_contr
		vol += vol_contr
	
	return vol

func add_facet(_facet, op : bool = false) -> void:
	if id == -1:
		push_error("Body volume has not been assigned to the geometry and has no valid id")
		return
	facets.append(_facet)
	var fid = _facet.get_id()
	if op:
		fid = -fid
		if fid == 0: fid = -0.1
	facet_ids.append(fid)
	
	_facet.connect_body(self, op)

func has_facet( facet ) -> bool:
	return facets.has(facet)

func remove() -> void:
	super()
	for f in facets:
		f.disconnect_body(self)
	
